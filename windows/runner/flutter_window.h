#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void CreateTrayIcon();
  void RemoveTrayIcon();
  void ShowTrayMenu();
  void ShowMainWindow();
  void QuitFromTray();
  void UpdateTrayMenuLabel();
  void UpdateTrayTooltip();
  void SendTrayEvent(const std::string& event_name, const flutter::EncodableMap& payload);
  void SetListeningEnabled(bool enabled);
  void RegisterClipboardListener();
  void UnregisterClipboardListener();
  void HandleClipboardUpdate();

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> tray_channel_;
  bool tray_icon_registered_ = false;
  bool listening_enabled_ = false;
  bool clipboard_listener_registered_ = false;
  bool is_quitting_ = false;
  HMENU tray_menu_ = nullptr;
  std::wstring tray_last_collected_time_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
