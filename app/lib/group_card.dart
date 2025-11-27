// lib/group_card.dart
import 'package:flutter/material.dart';
import 'group_detail_screen.dart'; // 상세 화면 연결

class GroupCard extends StatelessWidget {
  final String title;
  final List<String> tags;
  final int currentMember;
  final String deadline;
  final bool isRecruiting;
  final bool isLiked;

  const GroupCard({
    super.key,
    required this.title,
    required this.tags,
    required this.currentMember,
    required this.deadline,
    required this.isRecruiting,
    required this.isLiked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 카드 클릭 시 상세 페이지로 이동 (전체 화면 덮기)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailScreen(
              title: title,
              tags: tags,
              deadline: deadline,
              currentMember: currentMember,
              maxMember: 20,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                  color: isLiked ? const Color(0xFFFF5252) : const Color(0xFFBDBDBD),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) => Text(
                tag,
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.people_rounded, size: 18, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 6),
                Text(
                  '$currentMember명 모집',
                  style: const TextStyle(color: Color(0xFF757575), fontSize: 13),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 1,
                  height: 12,
                  color: const Color(0xFFE0E0E0),
                ),
                Text(
                  deadline,
                  style: TextStyle(
                    color: isRecruiting ? const Color(0xFFFF5252) : const Color(0xFFBDBDBD),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}