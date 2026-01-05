import 'package:flutter/material.dart';
import '../../screens/notice_search_screen.dart';
import '../common/bounceable.dart';

class NoticeSearchWidget extends StatelessWidget {
  const NoticeSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NoticeSearchScreen()),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E8EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF3182F6),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "공지사항 통합 검색",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333D4B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "찾으시는 공지사항이 있나요?",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
