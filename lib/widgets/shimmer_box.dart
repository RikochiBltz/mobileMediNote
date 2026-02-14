import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  final Color baseColor;
  final bool enabled;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
    required this.baseColor,
    this.enabled = true,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return _buildBox();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            final width = rect.width;
            final dx = (2 * width * _controller.value) - width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(0),
                Colors.white.withOpacity(0.28),
                Colors.white.withOpacity(0),
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(dx),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: _buildBox(),
        );
      },
    );
  }

  Widget _buildBox() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.baseColor,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double dx;

  const _SlidingGradientTransform(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}
