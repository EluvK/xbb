import 'package:get/get.dart';

class Translation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => _keys;

  static final Map<String, Map<String, String>> _keys = _TranslationHelper.loadTranslations();
}

class _TranslationHelper {
  // dart format off
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
    "add_task_widget_to_home": {
      "en_US": "Add to Home Screen",
      "zh_CN": "添加到桌面",
    },
    "task_widget_label": {
      "en_US": "Task Widget",
      "zh_CN": "任务桌面插件",
    },
    "add_task_widget_not_supported_title": {
      "en_US": "Not Supported",
      "zh_CN": "不支持自动添加",
    },
    "add_task_widget_not_supported_message": {
      "en_US": "Your launcher doesn't support pinning widgets directly. Please long-press the home screen, select \"Widgets\", and add the Task Widget manually.",
      "zh_CN": "当前桌面不支持直接添加插件，请长按桌面空白处，选择「插件」，找到任务插件手动添加。",
    },
    "app_version": {
      "en_US": "App Version @version",
      "zh_CN": "版本信息 @version",
    },
    "check_update": {
      "en_US": "Check for Update",
      "zh_CN": "查询更新",
    },
    "do_update": {
      "en_US": "Update",
      "zh_CN": "更新",
    },
    "download_manually": {
      "en_US": "Download Manually",
      "zh_CN": "手动下载",
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
    "confirm": {
      "en_US": "Confirm",
      "zh_CN": "确认",
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
    "search_title": {
      "en_US": "Search",
      "zh_CN": "搜索",
    },
    "mark_all_as_read": {
      "en_US": "Mark As Read",
      "zh_CN": "全部已读",
    },

    // --- Pages: Login & Profile (登录与个人资料) ---
    "login_page_title": {
      "en_US": "Login",
      "zh_CN": "登录",
    },
    "quick_login_title": {
      "en_US": "Quick Login",
      "zh_CN": "快速登录",
    },
    "quick_login_hint": {
      "en_US": "Click the avatar to login with saved credentials.",
      "zh_CN": "点击头像使用保存的凭据登录",
    },
    "non_quick_login_hint": {
      "en_US": "No quick login info yet.",
      "zh_CN": "暂无快速登录信息",
    },
    "save_for_quick_login_hint": {
      "en_US": "Save password",
      "zh_CN": "保存密码",
    },
    "delete_quick_login_message": {
      "en_US": "Delete quick login info for @userName?",
      "zh_CN": "删除 `@userName` 的快速登录信息吗？",
    },
    "login_with_different_account": {
      "en_US": "Use another account",
      "zh_CN": "使用其他账号登录",
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
    "home_bar_title_task": {
      "en_US": "Tasks",
      "zh_CN": "任务",
    },
    "task_section_history": {
      "en_US": "History",
      "zh_CN": "历史记录",
    },
    "task_section_workspace": {
      "en_US": "Workspace",
      "zh_CN": "工作区",
    },
    "task_action_archive_workspace": {
      "en_US": "Archive Workspace",
      "zh_CN": "归档工作区",
    },
    "task_action_add": {
      "en_US": "Task",
      "zh_CN": "任务",
    },
    "task_action_load_more_history": {
      "en_US": "Load more history",
      "zh_CN": "加载更多历史",
    },
    "task_action_show_history": {
      "en_US": "Show history",
      "zh_CN": "显示历史",
    },
    "task_action_history_loaded_all": {
      "en_US": "All Loaded",
      "zh_CN": "已全部加载",
    },
    "task_toggle_details": {
      "en_US": "Details",
      "zh_CN": "详情",
    },
    "task_action_show_details": {
      "en_US": "Show Details",
      "zh_CN": "展示详情",
    },
    "task_action_hide_details": {
      "en_US": "Hide Details",
      "zh_CN": "隐藏详情",
    },
    "task_collapse_archived": {
      "en_US": "Collapse",
      "zh_CN": "收起",
    },
    "task_expand_archived": {
      "en_US": "Expand",
      "zh_CN": "展开",
    },
    "task_empty_history_segment": {
      "en_US": "No tasks in this history segment.",
      "zh_CN": "该历史段无任务。",
    },
    "task_empty_workspace_hint": {
      "en_US": "No tasks in workspace. Tap Task below to create one.",
      "zh_CN": "当前工作区没有任务，点击下方任务按钮新增。",
    },
    "task_tap_to_edit_hint": {
      "en_US": "Tap to edit task",
      "zh_CN": "点击编辑任务内容",
    },
    "task_no_archivable_items": {
      "en_US": "No items to archive in workspace",
      "zh_CN": "当前没有可归档任务",
    },
    "task_saving": {
      "en_US": "Saving...",
      "zh_CN": "保存中...",
    },
    "task_time_unknown": {
      "en_US": "Unknown time",
      "zh_CN": "未知时间",
    },
    "task_time_empty": {
      "en_US": "-",
      "zh_CN": "-",
    },
    "task_status_todo": {
      "en_US": "Todo",
      "zh_CN": "未完成",
    },
    "task_status_done": {
      "en_US": "Done",
      "zh_CN": "已完成",
    },
    "task_overview_title": {
      "en_US": "Task Overview",
      "zh_CN": "任务概览",
    },
    "task_overview_subtitle": {
      "en_US": "Current active workspace status",
      "zh_CN": "当前活跃工作区状态",
    },
    "task_overview_done_ratio": {
      "en_US": "Completion: @percent",
      "zh_CN": "完成率：@percent",
    },
    "task_overview_total": {
      "en_US": "Total",
      "zh_CN": "总任务",
    },
    "task_overview_done": {
      "en_US": "Done",
      "zh_CN": "已完成",
    },
    "task_overview_todo": {
      "en_US": "Todo",
      "zh_CN": "未完成",
    },
    "task_overview_empty": {
      "en_US": "No tasks in current workspace",
      "zh_CN": "当前工作区暂无任务",
    },
    "task_detail_index": {
      "en_US": "Index",
      "zh_CN": "序号",
    },
    "task_detail_id": {
      "en_US": "ID",
      "zh_CN": "ID",
    },
    "task_detail_done_at": {
      "en_US": "Done At",
      "zh_CN": "完成时间",
    },
    "task_detail_updated_at": {
      "en_US": "Updated At",
      "zh_CN": "更新时间",
    },
    "task_confirm_archive_title": {
      "en_US": "Archive Workspace",
      "zh_CN": "归档工作区",
    },
    "task_confirm_archive_content": {
      "en_US": "Archive current workspace? This will create a new workspace.",
      "zh_CN": "确认归档当前工作区吗？归档后会自动创建新的工作区。",
    },
    "task_confirm_delete_title": {
      "en_US": "Delete Task",
      "zh_CN": "删除任务",
    },
    "task_confirm_delete_content": {
      "en_US": "Are you sure you want to delete this task?",
      "zh_CN": "确认删除这条任务吗？",
    },
    "task_delete_history": {
      "en_US": "Delete history segment",
      "zh_CN": "删除历史记录",
    },
    "task_confirm_delete_history_title": {
      "en_US": "Delete History Segment",
      "zh_CN": "删除历史记录",
    },
    "task_confirm_delete_history_content": {
      "en_US": "Delete this history segment? This action cannot be undone.",
      "zh_CN": "确认删除这段历史记录吗？该操作不可撤销。",
    },
    "home_bar_title_note": {
      "en_US": "Notes",
      "zh_CN": "笔记",
    },
    "home_bar_title_tracker": {
      "en_US": "Tracker",
      "zh_CN": "追踪",
    },
    "home_bar_title_setting": {
      "en_US": "Settings",
      "zh_CN": "设置",
    },
    "post_page_title_new": {
      "en_US": "New Post",
      "zh_CN": "新建帖子",
    },
    "post_page_title_edit": {
      "en_US": "Edit Post: @postName",
      "zh_CN": "编辑帖子: @postName",
    },
    "post_page_title_view": {
      "en_US": "View Post: @postName",
      "zh_CN": "查看帖子: @postName",
    },
    "repo_page_title_edit": {
      "en_US": "Edit Repo: @repoName",
      "zh_CN": "编辑仓库: @repoName",
    },
    "tracker_page_title_edit": {
      "en_US": "Edit Tracker",
      "zh_CN": "编辑追踪器",
    },
    "tracker_page_title_add": {
      "en_US": "Add Tracker",
      "zh_CN": "新增追踪器",
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
    "ping_latency_test": {
      "en_US": "Test Latency",
      "zh_CN": "测试延迟",
    },
    "ping_latency_testing": {
      "en_US": "Testing...",
      "zh_CN": "测试中...",
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
    "app_enable_tracker_feature": {
      "en_US": "Enable Tracker Feature",
      "zh_CN": "启用追踪功能",
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

    // --- Tracker: UI Texts ---
    "tracker_panic": {
      "en_US": "Tracker Error",
      "zh_CN": "追踪器异常",
    },
    "tracker_no_selection": {
      "en_US": "No tracker selected, should pass tracker here.",
      "zh_CN": "未选择追踪器，应该传入 tracker 参数。",
    },
    "tracker_category": {
      "en_US": "Category",
      "zh_CN": "分类",
    },
    "tracker_description": {
      "en_US": "Description",
      "zh_CN": "描述",
    },
    "tracker_type": {
      "en_US": "Type",
      "zh_CN": "类型",
    },
    "tracker_type_event": {
      "en_US": "Event",
      "zh_CN": "事件",
    },
    "tracker_type_milestone": {
      "en_US": "Milestone",
      "zh_CN": "里程碑",
    },
    "tracker_type_anniversary": {
      "en_US": "Anniversary",
      "zh_CN": "纪念日",
    },
    "tracker_edit_record": {
      "en_US": "Edit Record",
      "zh_CN": "编辑记录",
    },
    "tracker_add_record": {
      "en_US": "Add Record",
      "zh_CN": "新增记录",
    },
    "tracker_no_records": {
      "en_US": "No records yet",
      "zh_CN": "暂无记录",
    },
    "tracker_note": {
      "en_US": "Note",
      "zh_CN": "备注",
    },
    "tracker_record_time": {
      "en_US": "Record Happened At",
      "zh_CN": "记录发生时间",
    },
    "tracker_milestone_boolean_disabled": {
      "en_US": "Milestone(boolean) input is temporarily disabled in this version.",
      "zh_CN": "当前版本暂不支持 milestone(boolean) 记录录入",
    },
    "tracker_minutes_quick": {
      "en_US": "@minutes min",
      "zh_CN": "@minutes 分钟",
    },
    "tracker_hours_value": {
      "en_US": "@hours h",
      "zh_CN": "@hours 小时",
    },
    "tracker_duration_minutes": {
      "en_US": "Duration (minutes)",
      "zh_CN": "时长(分钟)",
    },
    "tracker_numeric_contribution": {
      "en_US": "Numeric Contribution",
      "zh_CN": "数值贡献",
    },
    "tracker_current_value": {
      "en_US": "Current Value",
      "zh_CN": "当前值",
    },
    "tracker_current_duration_minutes": {
      "en_US": "Current Duration (minutes)",
      "zh_CN": "当前时长(分钟)",
    },
    "tracker_progress_mode": {
      "en_US": "Progress Mode",
      "zh_CN": "进度模式",
    },
    "tracker_progress_mode_accumulate": {
      "en_US": "Accumulate",
      "zh_CN": "累计",
    },
    "tracker_progress_mode_latest": {
      "en_US": "Latest Value",
      "zh_CN": "最新值",
    },
    "tracker_anniversary_content": {
      "en_US": "Anniversary Content",
      "zh_CN": "纪念内容",
    },
    "tracker_write": {
      "en_US": "Write",
      "zh_CN": "写作",
    },
    "tracker_preview": {
      "en_US": "Preview",
      "zh_CN": "预览",
    },
    "tracker_anniversary_markdown_hint": {
      "en_US": "Markdown supported. Write what happened and your feelings...",
      "zh_CN": "支持 Markdown，记录当下发生了什么、你的感受或想法...",
    },
    "tracker_no_preview_content": {
      "en_US": "No content to preview",
      "zh_CN": "暂无内容可预览",
    },
    "tracker_input_error_title": {
      "en_US": "Input Error",
      "zh_CN": "输入错误",
    },
    "tracker_tip_title": {
      "en_US": "Notice",
      "zh_CN": "提示",
    },
    "tracker_anniversary_content_required": {
      "en_US": "Anniversary content cannot be empty",
      "zh_CN": "纪念内容不能为空",
    },
    "tracker_duration_minutes_error": {
      "en_US": "Duration must be a positive integer in minutes",
      "zh_CN": "时长必须是大于 0 的整数分钟",
    },
    "tracker_numeric_error": {
      "en_US": "Please enter a valid number",
      "zh_CN": "请输入有效数值",
    },
    "tracker_never_done": {
      "en_US": "Never done",
      "zh_CN": "从未记录",
    },
    "tracker_days_ago": {
      "en_US": "@days days ago",
      "zh_CN": "@days 天前",
    },
    "tracker_period_days": {
      "en_US": "Period: @days days",
      "zh_CN": "周期: @days 天",
    },
    "tracker_target_value": {
      "en_US": "Target: @value",
      "zh_CN": "目标: @value",
    },
    "tracker_current_target_value": {
      "en_US": "Current: @current / Target: @target",
      "zh_CN": "当前: @current / 目标: @target",
    },
    "tracker_today": {
      "en_US": "Today",
      "zh_CN": "今天",
    },
    "tracker_in_days": {
      "en_US": "In @days days",
      "zh_CN": "@days 天后",
    },
    "tracker_passed_days": {
      "en_US": "Passed @days days",
      "zh_CN": "已过 @days 天",
    },
    "tracker_since_base_days": {
      "en_US": "Since base: @days days",
      "zh_CN": "距预设日: @days 天",
    },
    "tracker_next_at_days": {
      "en_US": "Next at @next days (in @until days)",
      "zh_CN": "下一个节点: @next 天 (还有 @until 天)",
    },
    "tracker_base_date_value": {
      "en_US": "Base: @date",
      "zh_CN": "预设日: @date",
    },
    "tracker_delete_title": {
      "en_US": "Delete Tracker",
      "zh_CN": "删除追踪器",
    },
    "tracker_delete_confirm": {
      "en_US": "Are you sure you want to delete this tracker?",
      "zh_CN": "确定要删除这个追踪器吗？",
    },
    "tracker_error_with_message": {
      "en_US": "Error: @error",
      "zh_CN": "错误: @error",
    },
    "tracker_acl_after_creation": {
      "en_US": "ACL can be set after creation",
      "zh_CN": "创建后可设置 ACL",
    },
    "tracker_validation_error": {
      "en_US": "Validation Error",
      "zh_CN": "校验错误",
    },
    "tracker_name_required": {
      "en_US": "Name cannot be empty",
      "zh_CN": "名称不能为空",
    },
    "tracker_period_days_title": {
      "en_US": "Period Days",
      "zh_CN": "周期天数",
    },
    "tracker_period_days_helper": {
      "en_US": "0 for no cycle",
      "zh_CN": "0 表示无周期",
    },
    "tracker_goal_type": {
      "en_US": "Goal Type",
      "zh_CN": "目标类型",
    },
    "tracker_goal_time": {
      "en_US": "Time",
      "zh_CN": "时间",
    },
    "tracker_goal_number": {
      "en_US": "Number",
      "zh_CN": "数值",
    },
    "tracker_duration_hours": {
      "en_US": "Duration (hours)",
      "zh_CN": "时长(小时)",
    },
    "tracker_target_value_title": {
      "en_US": "Target Value",
      "zh_CN": "目标值",
    },
    "tracker_target": {
      "en_US": "Target",
      "zh_CN": "目标",
    },
    "tracker_boolean_target_hidden": {
      "en_US": "Boolean target is temporarily hidden",
      "zh_CN": "布尔目标暂时隐藏",
    },
    "tracker_base_date": {
      "en_US": "Base Date",
      "zh_CN": "预设日期",
    },
    "tracker_remind_type": {
      "en_US": "Remind Type",
      "zh_CN": "提醒类型",
    },
    "tracker_remind_per_year": {
      "en_US": "Per Year",
      "zh_CN": "每年",
    },
    "tracker_remind_per_100_days": {
      "en_US": "Per 100 Days",
      "zh_CN": "每 100 天",
    },
    "tracker_remind_t_minus": {
      "en_US": "T Minus",
      "zh_CN": "T 计时",
    },
    "tracker_access_control": {
      "en_US": "Access Control",
      "zh_CN": "访问控制",
    },
    "tracker_your_permissions": {
      "en_US": "Your Permissions",
      "zh_CN": "你的权限",
    },
    "tracker_perm_view": {
      "en_US": "View Tracker",
      "zh_CN": "查看追踪器",
    },
    "tracker_perm_edit": {
      "en_US": "Edit Tracker",
      "zh_CN": "编辑追踪器",
    },
    "tracker_perm_full_access": {
      "en_US": "Full Access",
      "zh_CN": "全部权限",
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
  // dart format on

  static Map<String, Map<String, String>> loadTranslations() {
    return convertTranslation(_translations);
  }

  static Map<String, Map<String, String>> convertTranslation(Map<String, dynamic> translations) {
    final Map<String, Map<String, String>> keys = {};

    translations.forEach((key, value) {
      value.forEach((lang, translation) {
        keys.putIfAbsent(lang, () => {})[key] = translation;
      });
    });
    // print(keys);
    return keys;
  }
}
