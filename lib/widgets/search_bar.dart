import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool showFilter;
  final VoidCallback? onFilterTap;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.showFilter = false,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.search, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: controller?.text.isNotEmpty ?? false
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          controller?.clear();
                          onClear?.call();
                        },
                      )
                    : null,
              ),
              onChanged: onChanged,
            ),
          ),
          if (showFilter && onFilterTap != null) ...[
            Container(
              width: 1,
              height: 24,
              color: AppColors.border,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: onFilterTap,
            ),
          ],
        ],
      ),
    );
  }
}
