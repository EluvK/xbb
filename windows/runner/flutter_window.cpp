#include "flutter_window.h"

#include <shellapi.h>
#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {

// GUID for the tray icon, used to ensure we can uniquely identify it when adding/removing.
constexpr wchar_t kTrayIconGuid[] = L"{4D03BD27-2462-493E-A53F-95B428F6DD11}";
constexpr UINT kTrayCallbackMessage = WM_APP + 101;
constexpr UINT kTrayMenuShowMainWindow = 2001;
constexpr UINT kTrayMenuToggleListening = 2002;
constexpr UINT kTrayMenuQuitApp = 2003;
constexpr wchar_t kTrayTipPrefix[] = L"xbb";

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  tray_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "com.eluvk.xbb/clipboard_tray",
      &flutter::StandardMethodCodec::GetInstance());
  tray_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method_name = call.method_name();
        if (method_name == "setListeningEnabled") {
          const flutter::EncodableValue* args = call.arguments();
          if (args == nullptr || !std::holds_alternative<bool>(*args)) {
            result->Error("invalid_args", "Expected a bool argument.");
            return;
          }
          listening_enabled_ = std::get<bool>(*args);
          UpdateTrayMenuLabel();
          UpdateTrayTooltip();
          result->Success();
          return;
        }
        if (method_name == "showMainWindow") {
          ShowMainWindow();
          result->Success();
          return;
        }
        if (method_name == "quitApp") {
          QuitFromTray();
          result->Success();
          return;
        }
        if (method_name == "updateTrayStatus") {
          if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
            auto listening_it = args->find(flutter::EncodableValue("listeningEnabled"));
            if (listening_it != args->end()) {
              if (const bool* value = std::get_if<bool>(&listening_it->second)) {
                listening_enabled_ = *value;
              }
            }
            auto timestamp_it = args->find(flutter::EncodableValue("lastCollectedTime"));
            if (timestamp_it != args->end()) {
              if (const std::string* value = std::get_if<std::string>(&timestamp_it->second)) {
                tray_last_collected_time_.assign(value->begin(), value->end());
              }
            }
          }
          UpdateTrayMenuLabel();
          UpdateTrayTooltip();
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  CreateTrayIcon();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveTrayIcon();
  if (tray_menu_ != nullptr) {
    DestroyMenu(tray_menu_);
    tray_menu_ = nullptr;
  }
  tray_channel_.reset();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_CLOSE:
      if (!is_quitting_) {
        ShowWindow(hwnd, SW_HIDE);
        return 0;
      }
      break;

    case kTrayCallbackMessage:
      if (LOWORD(lparam) == WM_RBUTTONUP || LOWORD(lparam) == WM_CONTEXTMENU) {
        ShowTrayMenu();
      } else if (LOWORD(lparam) == WM_LBUTTONDBLCLK) {
        ShowMainWindow();
      }
      return 0;

    case WM_COMMAND: {
      switch (LOWORD(wparam)) {
        case kTrayMenuShowMainWindow:
          ShowMainWindow();
          SendTrayEvent("onTrayShowMainWindow", flutter::EncodableMap());
          return 0;
        case kTrayMenuToggleListening: {
          listening_enabled_ = !listening_enabled_;
          UpdateTrayMenuLabel();
          UpdateTrayTooltip();
          SendTrayEvent(
              "onTrayToggleListening",
              flutter::EncodableMap{{flutter::EncodableValue("enabled"), flutter::EncodableValue(listening_enabled_)}});
          return 0;
        }
        case kTrayMenuQuitApp:
          SendTrayEvent("onTrayExitApp", flutter::EncodableMap());
          QuitFromTray();
          return 0;
      }
      break;
    }

    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::CreateTrayIcon() {
  if (tray_icon_registered_) {
    return;
  }

  if (tray_menu_ == nullptr) {
    tray_menu_ = CreatePopupMenu();
    AppendMenu(tray_menu_, MF_STRING, kTrayMenuShowMainWindow, L"Show Main Window");
    AppendMenu(tray_menu_, MF_STRING, kTrayMenuToggleListening, L"Resume Listening");
    AppendMenu(tray_menu_, MF_SEPARATOR, 0, nullptr);
    AppendMenu(tray_menu_, MF_STRING, kTrayMenuQuitApp, L"Exit App");
  }
  UpdateTrayMenuLabel();

  NOTIFYICONDATAW nid{};
  nid.cbSize = sizeof(NOTIFYICONDATAW);
  nid.hWnd = GetHandle();
  nid.uID = 1;
  nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_GUID;
  nid.uCallbackMessage = kTrayCallbackMessage;
  nid.hIcon = static_cast<HICON>(LoadImage(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON), IMAGE_ICON, 0, 0,
                                           LR_DEFAULTSIZE | LR_SHARED));
  IIDFromString(kTrayIconGuid, &nid.guidItem);
  wcscpy_s(nid.szTip, kTrayTipPrefix);

  if (Shell_NotifyIconW(NIM_ADD, &nid)) {
    nid.uVersion = NOTIFYICON_VERSION_4;
    Shell_NotifyIconW(NIM_SETVERSION, &nid);
    tray_icon_registered_ = true;
    UpdateTrayTooltip();
  }
}

void FlutterWindow::RemoveTrayIcon() {
  if (!tray_icon_registered_) {
    return;
  }

  NOTIFYICONDATAW nid{};
  nid.cbSize = sizeof(NOTIFYICONDATAW);
  nid.hWnd = GetHandle();
  nid.uID = 1;
  nid.uFlags = NIF_GUID;
  IIDFromString(kTrayIconGuid, &nid.guidItem);
  Shell_NotifyIconW(NIM_DELETE, &nid);

  tray_icon_registered_ = false;
}

void FlutterWindow::ShowTrayMenu() {
  if (tray_menu_ == nullptr) {
    return;
  }
  POINT cursor_pos;
  GetCursorPos(&cursor_pos);
  SetForegroundWindow(GetHandle());
  TrackPopupMenu(tray_menu_, TPM_RIGHTBUTTON, cursor_pos.x, cursor_pos.y, 0, GetHandle(), nullptr);
  PostMessage(GetHandle(), WM_NULL, 0, 0);
}

void FlutterWindow::ShowMainWindow() {
  ShowWindow(GetHandle(), SW_RESTORE);
  SetForegroundWindow(GetHandle());
}

void FlutterWindow::QuitFromTray() {
  if (is_quitting_) {
    return;
  }
  is_quitting_ = true;
  Destroy();
}

void FlutterWindow::UpdateTrayMenuLabel() {
  if (tray_menu_ == nullptr) {
    return;
  }
  ModifyMenu(tray_menu_, kTrayMenuToggleListening, MF_BYCOMMAND | MF_STRING, kTrayMenuToggleListening,
             listening_enabled_ ? L"Pause Listening" : L"Resume Listening");
}

void FlutterWindow::UpdateTrayTooltip() {
  if (!tray_icon_registered_) {
    return;
  }

  std::wstring tooltip = std::wstring(kTrayTipPrefix) + L" - " + (listening_enabled_ ? L"Listening" : L"Paused");
  if (!tray_last_collected_time_.empty()) {
    tooltip += L" - Last: ";
    tooltip += tray_last_collected_time_;
  }

  NOTIFYICONDATAW nid{};
  nid.cbSize = sizeof(NOTIFYICONDATAW);
  nid.hWnd = GetHandle();
  nid.uID = 1;
  nid.uFlags = NIF_TIP | NIF_GUID;
  IIDFromString(kTrayIconGuid, &nid.guidItem);
  wcsncpy_s(nid.szTip, tooltip.c_str(), _TRUNCATE);
  Shell_NotifyIconW(NIM_MODIFY, &nid);
}

void FlutterWindow::SendTrayEvent(const std::string& event_name, const flutter::EncodableMap& payload) {
  if (!tray_channel_) {
    return;
  }
  tray_channel_->InvokeMethod(event_name, std::make_unique<flutter::EncodableValue>(payload));
}
