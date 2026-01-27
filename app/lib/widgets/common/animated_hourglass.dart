import 'package:flutter/material.dart';

class AnimatedHourglass extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const AnimatedHourglass({
    super.key,
    this.size = 50.0,
    this.color = const Color(0xFF3182F6),
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedHourglass> createState() => _AnimatedHourglassState();
}

class _AnimatedHourglassState extends State<AnimatedHourglass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 0.0 -> 0.5 (180도 회전)
    // CurvedAnimation을 사용하여 쫀득한 느낌(Elastic/Bounce) 등 적용 가능
    // 여기서는 처음 요청했던 '쫀득한 회전' 느낌을 살림
    _animation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animation,
      child: Icon(
        Icons.hourglass_top_rounded,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
