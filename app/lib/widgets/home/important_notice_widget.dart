import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notice.dart';
import '../../screens/notice_detail_screen.dart';
import '../../screens/notice_list_screen.dart';
import '../common/bounceable.dart'; // Toss-style Interaction

class ImportantNoticeWidget extends StatefulWidget {
  final bool forceShow;

  const ImportantNoticeWidget({super.key, this.forceShow = false});

  @override
  State<ImportantNoticeWidget> createState() => _ImportantNoticeWidgetState();
}

class _ImportantNoticeWidgetState extends State<ImportantNoticeWidget> {
  Future<QuerySnapshot>? _noticesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    setState(() {
      _noticesFuture = FirebaseFirestore.instance
          .collection('notices')
          .where('is_important', isEqualTo: true)
          .limit(20)
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _noticesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        // Client-side Sort
        final notices = snapshot.data!.docs
            .map((doc) => Notice.fromFirestore(doc, []))
            .toList();

        notices.sort((a, b) => b.date.compareTo(a.date));
        final displayNotices = notices;

        if (displayNotices.isEmpty) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E8EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD180),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "중요 공지",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191F28),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF2F4F6)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      "아직은 중요 공지가 없어요",
                      style: TextStyle(
                        color: Color(0xFF8B95A1),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD180),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "중요 공지",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191F28),
                          ),
                        ),
                      ],
                    ),
                    Bounceable(
                      onTap: () {
                        // 전체보기 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NoticeListScreen(
                              title: "중요 공지",
                              themeColor: Color(0xFFFFD180),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: const Text(
                          "전체보기",
                          style: TextStyle(
                            color: Color(0xFF8B95A1),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF2F4F6)),
              // Content Area
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: Column(
                  // Show only top 3 items
                  children: displayNotices.take(3).map((notice) {
                    return _buildNoticeItem(context, notice);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoticeItem(BuildContext context, Notice notice) {
    return Bounceable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticeDetailScreen(notice: notice),
          ),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        visualDensity: const VisualDensity(vertical: -2), // Compact
        leading: const Icon(
          Icons.star_rounded,
          color: Color(0xFFFFD180),
          size: 24,
        ),
        title: Transform.translate(
          offset: const Offset(-16, 0), // Adjust icon spacing
          child: Text(
            notice.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333D4B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Text(
          notice.date.length > 5 ? notice.date.substring(5) : notice.date,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8B95A1)),
        ),
      ),
    );
  }
}
