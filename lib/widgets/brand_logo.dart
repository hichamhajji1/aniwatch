import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40, this.radius = 12});

  static const assetPath = 'assets/branding/app_icon.png';

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class AniWordmark extends StatelessWidget {
  const AniWordmark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: size, radius: size * 0.28),
        SizedBox(width: size * 0.28),
        Text(
          'AnShow Anime show',
          style: TextStyle(
            fontSize: size * 0.72,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
            letterSpacing: -0.4,
            height: 1,
            fontFamily: 'serif',
          ),
        ),
        Icon(Icons.play_arrow_rounded, color: AppColors.gold, size: size * 0.9),
      ],
    );
  }
}
