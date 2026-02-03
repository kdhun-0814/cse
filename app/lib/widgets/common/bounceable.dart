import 'package:flutter/material.dart';

class Bounceable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final Duration reverseDuration;
  final BorderRadius borderRadius; // 시각적 하이라이트를 위한 모양 정보
  final bool immediate; // 애니메이션 종료 대기 여부 (true: 즉시 실행, false: 애니메이션 종료 후 실행)

  const Bounceable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 100),
    this.reverseDuration = const Duration(milliseconds: 150),
    this.borderRadius = BorderRadius.zero, // 기본값
    this.immediate = false, // 기본값: Toss 스타일 (후 실행)
  });

  @override
  State<Bounceable> createState() => _BounceableState();
}

class _BounceableState extends State<Bounceable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  // 터치 상태 추적 (하이라이트용)
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutQuad,
            reverseCurve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true); // 눌림 상태 ON
      _controller.forward();
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      if (widget.immediate) {
        widget.onTap?.call();
      }

      // 무조건 끝까지 수축했다가 돌아오게 함 (Full Cycle Guarantee)
      _controller.forward().then((_) {
        if (mounted) {
          _controller.reverse().then((_) {
            if (mounted) {
              setState(() => _isPressed = false);
              if (!widget.immediate) {
                widget.onTap?.call(); // 애니메이션 종료 후 콜백 실행
              }
            }
          });
        }
      });
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && mounted) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _handleTapCancel();
  }

  void _onPointerUp(PointerUpEvent event) {
    // 드래그 후 터치가 끝났을 때(혹은 제스처가 취소되었을 때) 혹시라도 눌린 상태면 복구
    if (_isPressed && mounted) {
      _handleTapCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, // 터치 영역보장
        onTap: _handleTap,
        onTapCancel: _handleTapCancel,
        onTapDown: (_) {
           // GestureDetector가 제스처 아레나에 참여하도록 명시
           if (widget.onTap != null) {
             setState(() => _isPressed = true);
           }
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            fit: StackFit.passthrough, // 제약 조건(예: Expanded의 강제 너비)을 자식에게 그대로 전달
            children: [
              widget.child,
              // 하이라이트 오버레이
              Positioned.fill(
                child: IgnorePointer( // 터치 통과
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: _isPressed 
                          ? Colors.black.withOpacity(0.05) // 살짝 어두워짐
                          : Colors.transparent,
                      borderRadius: widget.borderRadius, // 모양 맞춤
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

