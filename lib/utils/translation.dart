import 'package:get/get.dart';

class Translation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => _keys;

  static final Map<String, Map<String, String>> _keys =
      _TranslationHelper.loadTranslations();
}

class _TranslationHelper {
  static final Map<String, dynamic> _translations = {
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
    "change_user": {
      "en_US": "Change User",
      "zh_CN": "切换用户",
    },
    "new_repo": {
      "en_US": "New Repo",
      "zh_CN": "创建新小本本",
    },
    "edit_repo": {
      "en_US": "Edit Repo `@repoName`",
      "zh_CN": "修改 `@repoName`",
    },
    "update_failed": {
      "en_US": "Update Failed",
      "zh_CN": "更新失败",
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
    "update_result_new_posts_cnt": {
      "en_US": "@count New Posts",
      "zh_CN": "新增 @count 篇笔记",
    },
    "update_result_update_posts_cnt": {
      "en_US": "@count Updated Posts",
      "zh_CN": "更新 @count 篇笔记",
    },
    "update_result_delete_posts_cnt": {
      "en_US": "@count Deleted Posts",
      "zh_CN": "删除 @count 篇笔记",
    },
    "update_result_nothing": {
      "en_US": "No Updates",
      "zh_CN": "没有任何更新噢。",
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
    "back_check_title": {
      "en_US": "Are you sure?",
      "zh_CN": "确定退出？",
    },
    "back_check_content": {
      "en_US": "Are you sure you want to leave this page?",
      "zh_CN": "未保存的内容会丢失",
    },
    "back_check_confirm": {
      "en_US": "Leave",
      "zh_CN": "确认离开",
    },
    "back_check_cancel": {
      "en_US": "Never Mind",
      "zh_CN": "取消",
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
