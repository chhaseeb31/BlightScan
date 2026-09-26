import 'package:flutter/material.dart';

/// ShimmerLoading - Premium skeleton loading with shimmer effect
/// Provides elegant loading states for lists, cards, and content areas
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget? child;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.child,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.25,
                1.0,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// ShimmerBox - Simple shimmer placeholder with flexible dimensions
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: width ?? double.infinity,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// ShimmerCard - Skeleton loading for card content
class ShimmerCard extends StatelessWidget {
  final double? width;
  final double height;

  const ShimmerCard({
    super.key,
    this.width,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: width ?? double.infinity,
      height: height,
      borderRadius: 12.0,
    );
  }
}

/// ShimmerList - Skeleton loading for list items
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
          child: ShimmerCard(height: itemHeight),
        );
      }),
    );
  }
}

/// ShimmerText - Skeleton loading for text lines
class ShimmerText extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;

  const ShimmerText({
    super.key,
    this.lines = 3,
    this.lineHeight = 16,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: ShimmerLoading(
            width: isLast ? 200 : double.infinity,
            height: lineHeight,
            borderRadius: 4,
          ),
        );
      }),
    );
  }
}

/// ShimmerCircle - Skeleton loading for circular elements (avatars)
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }
}

/// LoadingOverlay - Full screen loading overlay with shimmer
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(message!),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
