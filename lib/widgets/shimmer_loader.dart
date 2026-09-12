import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ShimmerLoader extends StatefulWidget {
  const ShimmerLoader({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(_controller.value * 2, 0),
              colors: const [
                AppColors.surfaceHigh,
                Color(0xFF2A2A2A),
                AppColors.surfaceHigh,
              ],
            ),
          ),
        );
      },
    );
  }
}

class PosterShimmerRow extends StatelessWidget {
  const PosterShimmerRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoader(width: 128, height: 176, radius: 16),
            SizedBox(height: 8),
            ShimmerLoader(width: 110, height: 12, radius: 6),
          ],
        ),
      ),
    );
  }
}
