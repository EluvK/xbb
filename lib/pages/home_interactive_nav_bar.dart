import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:xbb/pages/home.dart';

/// 移动端融合型交互式底部导航栏（基于 pie_menu 扇面手势生态打造）
/// 交互特性：
/// 1. 选中某个 Section 后，底部大标签的图标与文字实时联动展示当前具体的 feature
/// 2. 快速轻击（Tap）：若点击其他 Section 则切入；若点击当前 Section 则在子功能间顺次循环轮转
/// 3. 按住滑选（Press & Drag Scrubbing）：手指长按从按钮中心以 120° 物理弹性拱弧展开扇面，
///    手指不离屏滑动瞄准子功能，滑过哪个子功能哪个自动高亮放大并震动，松手瞬间确认生效
class MobileInteractiveNavigationBar extends StatelessWidget {
  const MobileInteractiveNavigationBar({
    super.key,
    required this.selectedTab,
    required this.activeIndices,
    required this.activeSections,
    required this.sectionActiveTabs,
    required this.onTabChanged,
    required this.onSectionSelected,
  });

  final HomeTabIndex selectedTab;
  final List<HomeTabIndex> activeIndices;
  final List<FeatureSection> activeSections;
  final Map<FeatureSection, HomeTabIndex> sectionActiveTabs;
  final ValueChanged<HomeTabIndex> onTabChanged;
  final ValueChanged<FeatureSection> onSectionSelected;

  List<HomeTabIndex> _getSectionActiveTabs(FeatureSection section) {
    return section.candidateTabs.where((t) => activeIndices.contains(t)).toList();
  }

  HomeTabIndex _getCurrentTabForSection(FeatureSection section) {
    final currentSection = sectionForTab(selectedTab);
    if (currentSection == section) {
      return selectedTab;
    }
    final remembered = sectionActiveTabs[section];
    final activeTabs = _getSectionActiveTabs(section);
    if (remembered != null && activeTabs.contains(remembered)) {
      return remembered;
    }
    return activeTabs.isNotEmpty ? activeTabs.first : section.candidateTabs.first;
  }

  void _handleTap(FeatureSection section) {
    final currentSection = sectionForTab(selectedTab);
    final availableTabs = _getSectionActiveTabs(section);

    if (currentSection != section) {
      // 切换到不同的 Section
      HapticFeedback.selectionClick();
      onSectionSelected(section);
    } else {
      // 点击已处于激活态的 Section：循环轮转下一个子功能
      if (availableTabs.length > 1) {
        final currentIndex = availableTabs.indexOf(selectedTab);
        final nextIndex = (currentIndex + 1) % availableTabs.length;
        final nextTab = availableTabs[nextIndex];
        HapticFeedback.selectionClick();
        onTabChanged(nextTab);
      }
    }
  }

  PieTheme _buildPieTheme(
    BuildContext context,
    FeatureSection section,
    int index,
    int totalSections,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 根据在底部栏中的水平排列位置做自适应微调，确保无论在靠左还是靠右，扇面均完美展现在屏幕安全区域内
    double customAngle = 90.0; // 默认垂直向上展开拱弧 (90°)
    if (totalSections >= 3) {
      if (index == 0) {
        customAngle = 76.0; // 最左侧标签：扇面微向右偏，贴合屏幕内侧
      } else if (index == totalSections - 1) {
        customAngle = 104.0; // 最右侧标签：扇面微向左偏
      }
    }

    return PieTheme(
      brightness: theme.brightness,
      overlayColor: Colors.black.withAlpha(45),
      radius: 56.0,
      buttonSize: 48.0,
      customAngle: customAngle,
      customAngleAnchor: PieAnchor.center,
      longPressDuration: const Duration(milliseconds: 140),
      childBounceEnabled: true,
      childBounceFactor: 0.94,
      pointerColor: Colors.transparent,
      pointerDecoration: const BoxDecoration(color: Colors.transparent),
      buttonTheme: PieButtonTheme(
        backgroundColor: colorScheme.surfaceContainerHigh,
        iconColor: colorScheme.onSurfaceVariant,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withAlpha(110),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 10.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
      buttonThemeHovered: PieButtonTheme(
        backgroundColor: colorScheme.primaryContainer,
        iconColor: colorScheme.onPrimaryContainer,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary.withAlpha(180),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(70),
              blurRadius: 16.0,
              spreadRadius: 1.5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      tooltipPadding: const EdgeInsets.only(bottom: 16.0),
      tooltipTextStyle: theme.textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentSection = sectionForTab(selectedTab);

    return Material(
      color: theme.navigationBarTheme.backgroundColor ?? colorScheme.surfaceContainer,
      elevation: 2.0,
      surfaceTintColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 0.5,
            color: theme.dividerColor.withAlpha(30),
          ),
          Container(
            height: 70.0,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: List.generate(activeSections.length, (sectionIndex) {
                final section = activeSections[sectionIndex];
                final isCurrentSection = section == currentSection;
                final availableTabs = _getSectionActiveTabs(section);
                final currentTab = _getCurrentTabForSection(section);
                final hasMultipleFeatures = availableTabs.length > 1;

                final tabItem = _BottomTabItem(
                  section: section,
                  currentTab: currentTab,
                  isSelected: isCurrentSection,
                  availableTabs: availableTabs,
                );

                // 单功能标签（如纯 AI）无需扇面，直接响应点击
                if (!hasMultipleFeatures) {
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleTap(section),
                      child: tabItem,
                    ),
                  );
                }

                // 多功能标签通过 PieMenu 赋予按压滑选能力
                return Expanded(
                  child: PieMenu(
                    theme: _buildPieTheme(
                      context,
                      section,
                      sectionIndex,
                      activeSections.length,
                    ),
                    onPressed: () => _handleTap(section),
                    actions: availableTabs.map((tab) {
                      return PieAction.builder(
                        tooltip: Text(
                          titleForTab(tab),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onSelect: () {
                          HapticFeedback.lightImpact();
                          onTabChanged(tab);
                        },
                        builder: (hovered) {
                          final isSelected = tab == selectedTab;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                iconDataForTab(tab),
                                size: hovered ? 21 : 18,
                                color: hovered
                                    ? colorScheme.onPrimaryContainer
                                    : (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                titleForTab(tab),
                                style: TextStyle(
                                  fontSize: 9.0,
                                  fontWeight: hovered || isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: hovered
                                      ? colorScheme.onPrimaryContainer
                                      : (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      );
                    }).toList(),
                    child: tabItem,
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

/// 单个底部导航按钮组件
class _BottomTabItem extends StatelessWidget {
  const _BottomTabItem({
    required this.section,
    required this.currentTab,
    required this.isSelected,
    required this.availableTabs,
  });

  final FeatureSection section;
  final HomeTabIndex currentTab;
  final bool isSelected;
  final List<HomeTabIndex> availableTabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasMultipleFeatures = availableTabs.length > 1;

    final activeIndex = availableTabs.indexOf(currentTab);
    final safeActiveIndex = activeIndex >= 0 ? activeIndex : 0;

    // 当 Section 处于激活态时，图标联动为当前具体选中的 feature；未选中时展示 Section 大类图标
    final IconData displayIcon = isSelected && hasMultipleFeatures
        ? iconDataForTab(currentTab)
        : (isSelected ? section.selectedIcon : section.icon);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 胶囊图标容器（遵循 Material 3 NavigationBar 胶囊规范）
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 58.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  displayIcon,
                  key: ValueKey<IconData>(displayIcon),
                  size: 22,
                  color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                ),
              ),
              // 若包含多个 Feature，在胶囊右上方展示微型分页指示点
              if (hasMultipleFeatures)
                Positioned(
                  top: 1,
                  right: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(availableTabs.length, (dotIndex) {
                      final isDotActive = isSelected && dotIndex == safeActiveIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 1.2),
                        width: isDotActive ? 7.0 : 3.2,
                        height: 3.2,
                        decoration: BoxDecoration(
                          color: isDotActive
                              ? colorScheme.primary
                              : (isSelected
                                  ? colorScheme.outline.withAlpha(120)
                                  : colorScheme.outline.withAlpha(80)),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3.0),
          // 文字标题：如果选中的是本 Section 且有特定子功能，显示当前具体子功能的标题
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            style: theme.textTheme.labelSmall!.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
            child: Text(
              isSelected && hasMultipleFeatures ? titleForTab(currentTab) : section.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
