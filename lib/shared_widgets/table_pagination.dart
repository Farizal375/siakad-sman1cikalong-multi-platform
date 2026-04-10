// File: lib/shared_widgets/table_pagination.dart
// ===========================================
// TABLE PAGINATION WIDGET
// Translated from TablePagination.tsx
// ===========================================

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class TablePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;

  const TablePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final int startItem = ((currentPage - 1) * itemsPerPage) + 1;
    final int endItem =
        (currentPage * itemsPerPage).clamp(0, totalItems);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Item count info
          Text(
            'Menampilkan $startItem-$endItem dari $totalItems data',
            style: const TextStyle(
              fontSize: 14, // text-sm
              color: AppColors.textMuted,
            ),
          ),

          // Page buttons
          Row(
            children: [
              // Previous
              _PageButton(
                onPressed:
                    currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                child: const Icon(Icons.chevron_left, size: 20),
              ),
              const SizedBox(width: 4),

              // Page numbers
              ...List.generate(totalPages, (index) {
                final page = index + 1;
                final isActive = page == currentPage;

                // Show limited page numbers (ellipsis logic)
                if (totalPages > 7) {
                  if (page != 1 &&
                      page != totalPages &&
                      (page < currentPage - 1 || page > currentPage + 1)) {
                    if (page == currentPage - 2 || page == currentPage + 2) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _PageButton(
                    isActive: isActive,
                    onPressed: () => onPageChanged(page),
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

              // Next
              _PageButton(
                onPressed: currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                child: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ],
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
