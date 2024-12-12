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
      "en_US": "New repo",
      "zh_CN": "创建",
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
