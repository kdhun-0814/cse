import 'package:flutter/material.dart';

class AnimatedBottomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimatedBottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<AnimatedBottomNavItem> createState() => _AnimatedBottomNavItemState();
}

class _AnimatedBottomNavItemState extends State<AnimatedBottomNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // 쫀득한 느낌을 위해 조금 길게
      vsync: this,
      value: widget.isSelected ? 1.0 : 0.0, // <-- 초기값 설정 (이미 선택된 상태면 1.0)
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut, // 물방울/젤리 효과 핵심
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedBottomNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? const Color(0xFF3182F6)
        : const Color(0xFFB0B8C1);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: widget.isSelected
                  ? _scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Icon(widget.icon, color: color, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
