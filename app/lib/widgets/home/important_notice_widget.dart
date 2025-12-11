import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notice.dart';
import '../../screens/notice_detail_screen.dart';

class ImportantNoticeWidget extends StatelessWidget {
  final bool forceShow;

  const ImportantNoticeWidget({super.key, this.forceShow = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .where('is_important', isEqualTo: true)
          // .orderBy('date', descending: true) // Index issue prevention: sort client-side
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // Client-side Sort
        final notices = snapshot.data!.docs
            .map((doc) => Notice.fromFirestore(doc, []))
            .toList();

        notices.sort((a, b) => b.date.compareTo(a.date));
        final displayNotices = notices.take(3).toList(); // Show top 3

        if (displayNotices.isEmpty) {
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
                  "중요 공지 (표시할 내용 없음)",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                "⭐ 중요 공지",
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
                children: displayNotices.asMap().entries.map((entry) {
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
                        leading: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD180),
                          size: 28,
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
                          notice.date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B95A1),
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
