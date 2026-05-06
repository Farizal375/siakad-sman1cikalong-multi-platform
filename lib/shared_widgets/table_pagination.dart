// File: lib/shared_widgets/table_pagination.dart
// ===========================================
// TABLE PAGINATION WIDGET
// Translated from TablePagination.tsx
// ===========================================

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class TablePagination extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChange;
  final ValueChanged<int>? onItemsPerPageChange;
  final String itemName;

  const TablePagination({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChange,
    this.onItemsPerPageChange,
    this.itemName = 'data',
  });

  int get totalPages => (totalItems / itemsPerPage).ceil().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    final int startItem = ((currentPage - 1) * itemsPerPage) + 1;
    final int endItem = (currentPage * itemsPerPage).clamp(0, totalItems);
    final isNarrow = MediaQuery.sizeOf(context).width < 560;
    final info = Text(
      'Menampilkan $startItem-$endItem dari $totalItems $itemName',
      style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
    );
    final buttons = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PageButton(
            onPressed: currentPage > 1
                ? () => onPageChange(currentPage - 1)
                : null,
            child: const Icon(Icons.chevron_left, size: 20),
          ),
          const SizedBox(width: 4),
          ...List.generate(totalPages, (index) {
            final page = index + 1;
            final isActive = page == currentPage;

            if (totalPages > 7) {
              if (page != 1 &&
                  page != totalPages &&
                  (page < currentPage - 1 || page > currentPage + 1)) {
                if (page == currentPage - 2 || page == currentPage + 2) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _PageButton(
                isActive: isActive,
                onPressed: () => onPageChange(page),
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? Colors.white : AppColors.foreground,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          _PageButton(
            onPressed: currentPage < totalPages
                ? () => onPageChange(currentPage + 1)
                : null,
            child: const Icon(Icons.chevron_right, size: 20),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 8), buttons],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [info, buttons],
            ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final VoidCallback? onPressed;

  const _PageButton({
    required this.child,
    this.isActive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: isActive ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: isActive
                    ? Colors.white
                    : onPressed != null
                    ? AppColors.foreground
                    : AppColors.textMuted,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
