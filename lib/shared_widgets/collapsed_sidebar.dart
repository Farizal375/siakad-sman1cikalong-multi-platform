// File: lib/shared_widgets/collapsed_sidebar.dart
// ===========================================
// COLLAPSIBLE SIDEBAR WIDGET
// Translated from CollapsedSidebar.tsx
// Global reusable sidebar for Admin/Kurikulum/Guru layouts
// ===========================================

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A single menu item in the sidebar
class SidebarMenuItem {
  final IconData icon;
  final String label;
  final String? route;
  final List<SidebarSubmenuItem>? submenuItems;
  final VoidCallback? onTap;

  const SidebarMenuItem({
    required this.icon,
    required this.label,
    this.route,
    this.submenuItems,
    this.onTap,
  });
}

/// A submenu item under a parent menu
class SidebarSubmenuItem {
  final String label;
  final String route;

  const SidebarSubmenuItem({
    required this.label,
    required this.route,
  });
}

class CollapsibleSidebar extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget? logoWidget;
  final List<SidebarMenuItem> menuItems;
  final List<SidebarMenuItem> bottomMenuItems;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool initialCollapsed;

  const CollapsibleSidebar({
    super.key,
    required this.title,
    this.subtitle = '',
    this.logoWidget,
    required this.menuItems,
    this.bottomMenuItems = const [],
    required this.currentRoute,
    required this.onNavigate,
    this.initialCollapsed = false,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  late bool _collapsed;
  final Set<String> _expandedMenus = {};

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initialCollapsed;
  }

  void _toggleMenu(String label) {
    setState(() {
      if (_expandedMenus.contains(label)) {
        _expandedMenus.remove(label);
      } else {
        _expandedMenus.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _collapsed ? 80 : 280,
      child: Container(
        color: AppColors.sidebarBg,
        child: Column(
          children: [
            // ── Logo & Title ──
            _buildHeader(),

            // ── Navigation Menu ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                child: Column(
                  children: widget.menuItems
                      .map((item) => _buildMenuItem(item))
                      .toList(),
                ),
              ),
            ),

            // ── Bottom Menu ──
            if (widget.bottomMenuItems.isNotEmpty)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.sidebarBorder, width: 1),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: widget.bottomMenuItems
                      .map((item) => _buildMenuItem(item))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24), // p-6
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.sidebarBorder, width: 1),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              // Logo
              widget.logoWidget ??
                  Container(
                    width: 48, // w-12
                    height: 48, // h-12
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
              if (!_collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle.isNotEmpty)
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Collapse toggle button
          Positioned(
            right: -36,
            top: 12,
            child: GestureDetector(
              onTap: () => setState(() => _collapsed = !_collapsed),
              child: Container(
                width: 24, // w-6
                height: 24, // h-6
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  _collapsed ? Icons.chevron_right : Icons.chevron_left,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(SidebarMenuItem item) {
    final bool isActive = widget.currentRoute == item.route;
    final bool hasSubmenu =
        item.submenuItems != null && item.submenuItems!.isNotEmpty;
    final bool isExpanded = _expandedMenus.contains(item.label);

    return Column(
      children: [
        // Main menu button
        Tooltip(
          message: _collapsed ? item.label : '',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (hasSubmenu && !_collapsed) {
                  _toggleMenu(item.label);
                } else if (item.onTap != null) {
                  item.onTap!();
                } else if (item.route != null) {
                  widget.onNavigate(item.route!);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: _collapsed ? 16 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: isActive ? Colors.white : AppColors.sidebarText,
                    ),
                    if (!_collapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: isActive ? Colors.white : AppColors.sidebarText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasSubmenu)
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Submenu
        if (hasSubmenu && !_collapsed)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Column(
                children: item.submenuItems!.map((subItem) {
                  final bool isSubActive = widget.currentRoute == subItem.route;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onNavigate(subItem.route),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSubActive
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSubActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                subItem.label,
                                style: TextStyle(
                                  color: isSubActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                  fontWeight: isSubActive
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

        const SizedBox(height: 4),
      ],
    );
  }
}
