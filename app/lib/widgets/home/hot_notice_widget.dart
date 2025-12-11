import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notice.dart';
import '../../screens/notice_detail_screen.dart';

class HotNoticeWidget extends StatelessWidget {
  final bool forceShow;

  const HotNoticeWidget({super.key, this.forceShow = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('views_today', descending: true) // NEW: 오늘 조회수 기준
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final notices = snapshot.data!.docs
            .map((doc) => Notice.fromFirestore(doc, []))
            .toList();

        if (notices.isEmpty) {
          if (forceShow) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Text(
                  "HOT 공지 (표시할 내용 없음)",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          // 데이터 없으면 숨김
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "🔥 HOT 공지",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191F28),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E8EB)),
              ),
              child: Column(
                children: notices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final notice = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NoticeDetailScreen(notice: notice),
                            ),
                          );
                        },
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: index < 3
                                ? const Color(0xFF3182F6)
                                : const Color(0xFFF2F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                color: index < 3
                                    ? Colors.white
                                    : const Color(0xFF8B95A1),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          notice.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333D4B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          "${notice.views}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF5252), // Hot color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (index != notices.length - 1)
                        const Divider(
                          height: 1,
                          color: Color(0xFFF2F4F6),
                          indent: 20,
                          endIndent: 20,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
