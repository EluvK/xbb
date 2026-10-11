import 'package:flutter/material.dart';

/// 预设矢量头像信息
class PresetAvatarItem {
  final String key;
  final String label;
  final IconData icon;
  final Color backgroundColor;

  const PresetAvatarItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
  });
}

/// 预设矢量头像清单
const List<PresetAvatarItem> kPresetAvatars = [
  PresetAvatarItem(
    key: 'preset_avatar_1',
    label: '默认',
    icon: Icons.person,
    backgroundColor: Color(0xFF6750A4),
  ),
  PresetAvatarItem(
    key: 'preset_avatar_2',
    label: '微笑',
    icon: Icons.face,
    backgroundColor: Color(0xFF006C4C),
  ),
  PresetAvatarItem(
    key: 'preset_avatar_3',
    label: '开心',
    icon: Icons.sentiment_very_satisfied,
    backgroundColor: Color(0xFFBA1A1A),
  ),
  PresetAvatarItem(
    key: 'preset_avatar_4',
    label: '萌宠',
    icon: Icons.pets,
    backgroundColor: Color(0xFF984061),
  ),
  PresetAvatarItem(
    key: 'preset_avatar_5',
    label: '机器人',
    icon: Icons.smart_toy,
    backgroundColor: Color(0xFF00639B),
  ),
  PresetAvatarItem(
    key: 'preset_avatar_6',
    label: '火箭',
    icon: Icons.rocket_launch,
    backgroundColor: Color(0xFF705D00),
  ),
  PresetAvatarItem(
    key: 'preset_avatar_7',
    label: '学者',
    icon: Icons.school,
    backgroundColor: Color(0xFF386568),
  ),
  PresetAvatarItem(
    key: 'preset_avatar_8',
    label: '电竞',
    icon: Icons.sports_esports,
    backgroundColor: Color(0xFF555F71),
  ),
];

/// 现代全功能头像渲染组件 (UserAvatarWidget)
class UserAvatarWidget extends StatelessWidget {
  final String? avatar;
  final String? fallbackName;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatarWidget({
    super.key,
    this.avatar,
    this.fallbackName,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avt = avatar?.trim() ?? '';
    final name = fallbackName?.trim() ?? '';

    Widget content;

    if (avt.startsWith('http://') || avt.startsWith('https://')) {
      content = CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: Image.network(
            avt,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(theme, name),
          ),
        ),
      );
    } else {
      final preset = kPresetAvatars.cast<PresetAvatarItem?>().firstWhere(
            (p) => p?.key == avt,
            orElse: () => null,
          );

      if (preset != null) {
        content = CircleAvatar(
          radius: radius,
          backgroundColor: preset.backgroundColor,
          child: Icon(preset.icon, size: radius * 1.1, color: Colors.white),
        );
      } else {
        content = _buildFallback(theme, name);
      }
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: content,
      );
    }
    return content;
  }

  Widget _buildFallback(ThemeData theme, String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
