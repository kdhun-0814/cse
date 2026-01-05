import 'package:flutter/material.dart';
import 'common/jelly_button.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;
  final bool enabled;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        JellyButton(
          isActive: widget.isLiked,
          activeIcon: Icons.favorite_rounded,
          inactiveIcon: Icons.favorite_border_rounded,
          activeColor: const Color(0xFFFF4E4E),
          inactiveColor: const Color(0xFFB0B8C1),
          size: 24,
          onTap: widget.onTap,
          enabled: widget.enabled,
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
    );
  }
}
