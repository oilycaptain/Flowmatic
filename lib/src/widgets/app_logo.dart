import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.primary, cs.secondary],
            ),
          ),
          child: Icon(Icons.water_drop_rounded, color: cs.onPrimary, size: size * 0.55),
        ),
        const SizedBox(width: 12),
        Text(
          'FlowMatic',
          style: TextStyle(fontSize: size * 0.55, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
