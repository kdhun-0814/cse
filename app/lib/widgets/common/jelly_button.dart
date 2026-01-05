import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JellyButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final bool enabled;

  const JellyButton({
    super.key,
    required this.isActive,
    required this.onTap,
    this.activeIcon = Icons.bookmark_rounded,
    this.inactiveIcon = Icons.bookmark_border_rounded,
    this.activeColor = const Color(0xFFFFD180),
    this.inactiveColor = const Color(0xFFD1D6DB),
    this.size = 24,
    this.enabled = true,
  });

  @override
  State<JellyButton> createState() => _JellyButtonState();
}

class _JellyButtonState extends State<JellyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant JellyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부 상태가 변했을 때(false -> true) 애니메이션 실행
    if (widget.isActive && !oldWidget.isActive) {
      _animate();
    }
  }

  void _animate() {
    _controller.forward().then((_) => _controller.reverse());
  }

  void _handleTap() {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact(); // 햅틱 피드백 추가
    // 탭 시 애니메이션 먼저 실행하고 콜백 호출
    _animate();
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.translucent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.isActive ? widget.activeIcon : widget.inactiveIcon,
          color: widget.isActive ? widget.activeColor : widget.inactiveColor,
          size: widget.size,
        ),
      ),
    );
  }
}
