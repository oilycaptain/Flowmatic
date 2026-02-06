import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(caption!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
                ]
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
