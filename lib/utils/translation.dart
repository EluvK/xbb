import 'package:get/get.dart';

class Translation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => _keys;

  static final Map<String, Map<String, String>> _keys =
      _TranslationHelper.loadTranslations();
}
class _TranslationHelper {
  static final Map<String, dynamic> _translations = {
    // --- Components: ACL & Members (权限管理) ---
    "no_members_with_permissions": {
      "en_US": "No members with permissions.",
      "zh_CN": "暂无成员拥有权限",
    },
    "no_members_with_permissions_yet": {
      "en_US": "No members with permissions yet.",
      "zh_CN": "目前还没有成员拥有权限",
    },
    "save_permission_changes": {
      "en_US": "Save Permission Changes",
      "zh_CN": "保存权限变更",
    },
    "add_members": {
      "en_US": "Add Members",
      "zh_CN": "添加成员",
    },

    // --- Components: Common & Settings (通用与设置) ---
    "unknown_user": {
      "en_US": "Unknown User",
      "zh_CN": "未知用户",
    },
    "change_user": {
      "en_US": "Change User",
      "zh_CN": "切换用户",
    },
    "friend_profiles": {
      "en_US": "Friend Profiles",
      "zh_CN": "好友资料",
    },
    "refresh": {
      "en_US": "Refresh",
      "zh_CN": "刷新",
    },
    "app_setting": {
      "en_US": "App Settings",
      "zh_CN": "应用设置",
    },
    "syncstore_setting": {
      "en_US": "SyncStore Settings",
      "zh_CN": "同步存储设置",
    },
    "app_feature_management": {
      "en_US": "Feature Management",
      "zh_CN": "功能管理",
    },
    "app_version": {
      "en_US": "App Version",
      "zh_CN": "版本信息",
    },
    "mode_light": {
      "en_US": "Light Mode",
      "zh_CN": "亮色模式",
    },
    "mode_system": {
      "en_US": "System Default",
      "zh_CN": "跟随系统",
    },
    "mode_dark": {
      "en_US": "Dark Mode",
      "zh_CN": "暗黑模式",
    },

    // --- Components: Notes & Editor (笔记与编辑器) ---
    "reply": {
      "en_US": "Reply",
      "zh_CN": "回复",
    },
    "edit": {
      "en_US": "Edit",
      "zh_CN": "编辑",
    },
    "delete": {
      "en_US": "Delete",
      "zh_CN": "删除",
    },
    "delete_comment": {
      "en_US": "Delete Comment",
      "zh_CN": "删除评论",
    },
    "cancel": {
      "en_US": "Cancel",
      "zh_CN": "取消",
    },
    "save": {
      "en_US": "Save",
      "zh_CN": "保存",
    },
    "update_repo_info": {
      "en_US": "Update Repo Info",
      "zh_CN": "更新仓库信息",
    },
    "repo_info": {
      "en_US": "Repo Info",
      "zh_CN": "仓库信息",
    },
    "update_repo_acl": {
      "en_US": "Update Repo ACL",
      "zh_CN": "更新仓库权限",
    },
    "repo_acl": {
      "en_US": "Repo ACL",
      "zh_CN": "仓库权限",
    },
    "perm_spy": {
      "en_US": "Spy",
      "zh_CN": "只读查看",
    },
    "perm_subscribe": {
      "en_US": "Subscribe",
      "zh_CN": "阅读与评论",
    },
    "perm_share": {
      "en_US": "Share",
      "zh_CN": "读写更新",
    },
    "perm_full_access": {
      "en_US": "Full Access",
      "zh_CN": "全部权限",
    },
    "expand_less_all": {
      "en_US": "Collapse All",
      "zh_CN": "全部收起",
    },
    "expand_more_all": {
      "en_US": "Expand All",
      "zh_CN": "全部展开",
    },

    // --- Pages: Login & Profile (登录与个人资料) ---
    "login_page_title": {
      "en_US": "Login",
      "zh_CN": "登录",
    },
    "service_status_ok": {
      "en_US": "Service Available",
      "zh_CN": "服务在线",
    },
    "service_status_not_available": {
      "en_US": "Service Not Available",
      "zh_CN": "服务不可用",
    },
    "service_status_checking": {
      "en_US": "Checking Service Status...",
      "zh_CN": "正在检测服务状态...",
    },
    "user_name": {
      "en_US": "Username",
      "zh_CN": "用户名",
    },
    "password": {
      "en_US": "Password",
      "zh_CN": "密码",
    },
    "login": {
      "en_US": "Login",
      "zh_CN": "登录",
    },
    "login_failed": {
      "en_US": "Login Failed",
      "zh_CN": "登录失败",
    },
    "login_success_message": {
      "en_US": "Welcome back, @userName!",
      "zh_CN": "欢迎回来, @userName!",
    },
    "login_failed_message": {
      "en_US": "Please check your username and password.",
      "zh_CN": "请检查用户名和密码",
    },
    "edit_profile": {
      "en_US": "Edit Profile",
      "zh_CN": "编辑资料",
    },
    "change_nick_name": {
      "en_US": "Change Nick Name",
      "zh_CN": "修改昵称",
    },
    "change_password": {
      "en_US": "Change Password",
      "zh_CN": "修改密码",
    },
    "input_optional_avatar_url": {
      "en_US": "Avatar URL (Optional)",
      "zh_CN": "头像链接 (可选)",
    },

    // --- Pages: Route Titles (页面标题/动态参数) ---
    "new_post": {
      "en_US": "New Post",
      "zh_CN": "新建帖子",
    },
    "edit_post": {
      "en_US": "Edit Post: @postName",
      "zh_CN": "编辑帖子: @postName",
    },
    "view_post": {
      "en_US": "View Post: @postName",
      "zh_CN": "查看帖子: @postName",
    },
    "edit_repo": {
      "en_US": "Edit Repo: @repoName",
      "zh_CN": "编辑仓库: @repoName",
    },

    // --- Utils: Feedback & Sync (提示与同步结果) ---
    "clear_child_data_plz": {
      "en_US": "Please clear child data first.",
      "zh_CN": "请先清理子数据",
    },
    "double_click_title": {
      "en_US": "Double Click to Confirm",
      "zh_CN": "双击以确认",
    },
    "back_check_title": {
      "en_US": "Unsaved Changes",
      "zh_CN": "更改未保存",
    },
    "back_check_content": {
      "en_US": "Are you sure you want to leave? Your changes will be lost.",
      "zh_CN": "确定要离开吗？未保存的内容将会丢失。",
    },
    "back_check_cancel": {
      "en_US": "Stay",
      "zh_CN": "留下",
    },
    "back_check_confirm": {
      "en_US": "Leave",
      "zh_CN": "离开",
    },
    // --- Utils: Template (模板) ---
    "app_server_url": {
      "en_US": "App Server URL",
      "zh_CN": "服务器地址",
    },
    "app_enable_tunnel": {
      "en_US": "Enable Tunnel",
      "zh_CN": "启用隧道",
    },
    "app_theme_mode": {
      "en_US": "Theme Mode",
      "zh_CN": "主题模式",
    },
    "app_language": {
      "en_US": "Language",
      "zh_CN": "语言",
    },
    "app_font_scale": {
      "en_US": "Font Scale",
      "zh_CN": "字体缩放",
    },
    "app_enable_note_feature": {
      "en_US": "Enable Note Feature",
      "zh_CN": "启用笔记功能",
    },
    "app_enable_setting": {
      "en_US": "Enable Setting",
      "zh_CN": "启用设置",
    },
    "input_title": {
      "en_US": "Title",
      "zh_CN": "名称",
    },
    "input_description": {
      "en_US": "Description",
      "zh_CN": "描述",
    },
    "input_saved": {
      "en_US": "Saved",
      "zh_CN": "已保存",
    },
    "optional": {
      "en_US": "(Optional)",
      "zh_CN": "(可选)",
    },
//   }; // below is old. keep for a while.
// }
// class _TranslationHelper {
//   static final Map<String, dynamic> _translations = {
    "app_name": {
      "en_US": "xbb",
      "zh_CN": "小本本",
    },
    "my_repos": {
      "en_US": "MyRepos",
      "zh_CN": "我的",
    },
    "subscribe_repos": {
      "en_US": "Subscribes",
      "zh_CN": "订阅的",
    },
    "refresh_tooltip": {
      "en_US": "update all",
      "zh_CN": "全部更新",
    },
    "new_repo": {
      "en_US": "New Repo",
      "zh_CN": "创建新小本本",
    },
    "comment_list": {
      "en_US": "Comments",
      "zh_CN": "评论列表",
    },
    "new_comment": {
      "en_US": "New Comment",
      "zh_CN": "写评论",
    },
    "reply_comment": {
      "en_US": "@ Reply To @id",
      "zh_CN": "@ 回复 @id",
    },
    "cancel_reply": {
      "en_US": "Cancel Reply",
      "zh_CN": "取消回复",
    },
    "my_repo_update": {
      "en_US": "Sync My Repos",
      "zh_CN": "同步成功",
    },
    "subscribe_repo_update": {
      "en_US": "Pull Subscribe Repos",
      "zh_CN": "订阅更新",
    },
    "update_current_repo": {
      "en_US": "Update Current Repo",
      "zh_CN": "更新当前仓库",
    },
    "repo_type_self": {
      "en_US": "Self",
      "zh_CN": "我的",
    },
    "repo_type_shared": {
      "en_US": "Shared",
      "zh_CN": "订阅",
    },
    "repo_name": {
      "en_US": "Repo Name",
      "zh_CN": "小本本命名",
    },
    "description": {
      "en_US": "Description",
      "zh_CN": "描述",
    },
    "shared_link": {
      "en_US": "Shared Link",
      "zh_CN": "分享链接",
    },
    "setting": {
      "en_US": "Setting",
      "zh_CN": "设置",
    },
    "sync_setting": {
      "en_US": "Sync Setting",
      "zh_CN": "同步设置",
    },
    "theme_mode": {
      "en_US": "Theme Mode",
      "zh_CN": "主题模式",
    },
    "language": {
      "en_US": "Language",
      "zh_CN": "语言",
    },
    "font_scale": {
      "en_US": "Font Scale",
      "zh_CN": "字体缩放",
    },
    "auto_check_app_update": {
      "en_US": "Check App Update At StartUp",
      "zh_CN": "启动时检查软件更新",
    },
    "check_app_update": {
      "en_US": "Check App Update",
      "zh_CN": "检查软件更新",
    },
    "do_app_update": {
      "en_US": "Download Update",
      "zh_CN": "下载新版本 APP",
    },
    "auto_sync_self_repo": {
      "en_US": "Sync Self Repo At Startup",
      "zh_CN": "启动时同步我的小本本",
    },
    "auto_sync_subscribe_repo": {
      "en_US": "Sync Subscribe Repo At Startup",
      "zh_CN": "启动时同步订阅的小本本",
    },
    "template": {
      "en_US": "",
      "zh_CN": "",
    }
  };

  static Map<String, Map<String, String>> loadTranslations() {
    return convertTranslation(_translations);
  }

  static Map<String, Map<String, String>> convertTranslation(
      Map<String, dynamic> translations) {
    final Map<String, Map<String, String>> keys = {};

    translations.forEach((key, value) {
      value.forEach((lang, translation) {
        keys.putIfAbsent(lang, () => {})[key] = translation;
      });
    });
    print(keys);
    return keys;
  }
}
