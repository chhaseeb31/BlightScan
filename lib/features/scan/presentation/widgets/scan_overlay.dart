import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';

class ScanOverlay extends StatefulWidget {
  final Rect frameRect;
  final double borderRadius;
  final Color accentColor;

  const ScanOverlay({
    super.key,
    required this.frameRect,
    required this.borderRadius,
    required this.accentColor,
  });

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // Cutout background
        IgnorePointer(
          child: CustomPaint(
            painter: _ScanCutoutPainter(
              frameRect: widget.frameRect,
              borderRadius: widget.borderRadius,
              overlayColor: theme.colorScheme.scrim.withValues(alpha: 0.66),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        
        // Frame Brackets
        Positioned.fromRect(
          rect: widget.frameRect,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: widget.frameRect.width,
                height: widget.frameRect.height,
                child: CustomPaint(
                  painter: _ScannerBracketPainter(
                    borderRadius: widget.borderRadius,
                    color: widget.accentColor,
                  ),
                ),
              ),
              
              // Animated Scan Line
              SizedBox(
                width: widget.frameRect.width,
                height: widget.frameRect.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) => Stack(
                      children: [
                        Positioned(
                          top: _animation.value * (widget.frameRect.height - 2),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: widget.accentColor.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  widget.accentColor,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Hint Text
              Positioned(
                bottom: -75,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Align tomato leaf here',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanCutoutPainter extends CustomPainter {
  final Rect frameRect;
  final double borderRadius;
  final Color overlayColor;

  _ScanCutoutPainter({
    required this.frameRect,
    required this.borderRadius,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutoutRRect = RRect.fromRectAndRadius(frameRect, Radius.circular(borderRadius));

    final path = Path()
      ..addRect(outerRect)
      ..addRRect(cutoutRRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanCutoutPainter oldDelegate) =>
      oldDelegate.frameRect != frameRect;
}

class _ScannerBracketPainter extends CustomPainter {
  final double borderRadius;
  final Color color;

  _ScannerBracketPainter({required this.borderRadius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const length = 30.0;
    final radius = borderRadius;

    // TL
    canvas.drawPath(
        Path()
          ..moveTo(0, length)
          ..lineTo(0, radius)
          ..quadraticBezierTo(0, 0, radius, 0)
          ..lineTo(length, 0),
        paint);
    // TR
    canvas.drawPath(
        Path()
          ..moveTo(size.width - length, 0)
          ..lineTo(size.width - radius, 0)
          ..quadraticBezierTo(size.width, 0, size.width, radius)
          ..lineTo(size.width, length),
        paint);
    // BL
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height - length)
          ..lineTo(0, size.height - radius)
          ..quadraticBezierTo(0, size.height, radius, size.height)
          ..lineTo(length, size.height),
        paint);
    // BR
    canvas.drawPath(
        Path()
          ..moveTo(size.width - length, size.height)
          ..lineTo(size.width - radius, size.height)
          ..quadraticBezierTo(size.width, size.height, size.width, size.height - radius)
          ..lineTo(size.width, size.height - length),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
