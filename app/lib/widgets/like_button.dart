import 'package:flutter/material.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부 상태가 변했을 때(예: 스트림 업데이트로 인한 리빌드) 
    // 좋아요가 false -> true로 변하면 애니메이션 실행
    if (widget.isLiked && !oldWidget.isLiked) {
      _animate();
    }
  }

  void _animate() {
    _controller.forward().then((_) => _controller.reverse());
  }

  void _handleTap() {
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
      behavior: HitTestBehavior.translucent, // 터치 영역 확보
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: widget.isLiked ? const Color(0xFFFF4E4E) : const Color(0xFFB0B8C1),
              size: 24,
            ),
          ),
          const SizedBox(height: 2), // 아이콘과 숫자 사이 간격
          Text(
            "${widget.likeCount}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.isLiked ? const Color(0xFFFF4E4E) : const Color(0xFF8B95A1),
            ),
          ),
        ],
      ),
    );
  }
}
