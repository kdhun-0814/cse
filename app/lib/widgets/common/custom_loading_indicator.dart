import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const CustomLoadingIndicator({
    super.key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? const Color(0xFF3182F6), // Brand Blue default
        strokeWidth: strokeWidth,
      ),
    );
  }
}
