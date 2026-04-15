// File: lib/shared_widgets/collapsed_sidebar.dart
// ===========================================
// COLLAPSIBLE SIDEBAR WIDGET (v2)
// Properly shows icon-only when collapsed.
// Toggle button exposed via callback for TopBar integration.
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
  /// Optional section label displayed above this item (e.g., "WALI KELAS")
  final String? sectionLabel;

  const SidebarMenuItem({
    required this.icon,
    required this.label,
    this.route,
    this.submenuItems,
    this.onTap,
    this.sectionLabel,
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

/// Controller for managing sidebar collapse state from parent layouts
class SidebarController extends ChangeNotifier {
  bool _collapsed;
  SidebarController({bool initialCollapsed = false}) : _collapsed = initialCollapsed;

  bool get isCollapsed => _collapsed;

  void toggle() {
    _collapsed = !_collapsed;
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════
// COLLAPSIBLE SIDEBAR
// ═══════════════════════════════════════════════
class CollapsibleSidebar extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget? logoWidget;
  final List<SidebarMenuItem> menuItems;
  final List<SidebarMenuItem> bottomMenuItems;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final SidebarController controller;

  const CollapsibleSidebar({
    super.key,
    required this.title,
    this.subtitle = '',
    this.logoWidget,
    required this.menuItems,
    this.bottomMenuItems = const [],
    required this.currentRoute,
    required this.onNavigate,
    required this.controller,
  });

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  final Set<String> _expandedMenus = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CollapsibleSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  bool get _collapsed => widget.controller.isCollapsed;

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
      curve: Curves.easeInOut,
      width: _collapsed ? 72 : 260,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.sidebarBorder, width: 1)),
      ),
      child: Column(
        children: [
          // ── Logo & Title ──
          _buildHeader(),

          // ── Navigation Menu ──
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: _collapsed ? 8 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                border: Border(top: BorderSide(color: AppColors.sidebarBorder, width: 1)),
              ),
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: _collapsed ? 8 : 12,
              ),
              child: Column(
                children: widget.bottomMenuItems
                    .map((item) => _buildMenuItem(item))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: _collapsed ? 12 : 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.sidebarBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Logo icon
          widget.logoWidget ??
              Container(
                width: _collapsed ? 40 : 44,
                height: _collapsed ? 40 : 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('assets/images/logoSekolah.png', fit: BoxFit.contain),
                ),
              ),

          // Title + subtitle (hidden when collapsed)
          if (!_collapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (widget.subtitle.isNotEmpty)
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(SidebarMenuItem item) {
    final bool isActive = _isRouteActive(item.route);
    final bool hasSubmenu =
        item.submenuItems != null && item.submenuItems!.isNotEmpty;
    final bool isExpanded = _expandedMenus.contains(item.label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        if (item.sectionLabel != null && !_collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              item.sectionLabel!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        if (item.sectionLabel != null && _collapsed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                width: 24,
                height: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),

        // Main menu button
        Tooltip(
          message: _collapsed ? item.label : '',
          waitDuration: const Duration(milliseconds: 400),
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
              borderRadius: BorderRadius.circular(10),
              hoverColor: Colors.white.withValues(alpha: 0.08),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: _collapsed ? 0 : 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8)]
                      : null,
                ),
                child: _collapsed
                    ? Center(
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: isActive ? Colors.white : AppColors.sidebarText,
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isActive ? Colors.white : AppColors.sidebarText,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isActive ? Colors.white : AppColors.sidebarText,
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSubActive
                              ? Colors.white.withValues(alpha: 0.15)
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
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                subItem.label,
                                style: TextStyle(
                                  color: isSubActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.55),
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

        SizedBox(height: _collapsed ? 4 : 2),
      ],
    );
  }

  bool _isRouteActive(String? route) {
    if (route == null) return false;
    final current = widget.currentRoute;
    if (current == route) return true;
    // pattern matching for sub-routes
    if (route.endsWith('/') && current.startsWith(route)) return true;
    return false;
  }
}
