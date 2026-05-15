import 'package:flutter/material.dart';
import 'package:fabri_sync/utils/customcolors.dart';

class ResponsiveTitleActionHeader extends StatelessWidget {
  final String title;
  final Widget action;

  const ResponsiveTitleActionHeader({
    super.key,
    required this.title,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final narrow = constraints.maxWidth < 520;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }

        return Row(
          children: [
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            action,
          ],
        );
      },
    );
  }
}
