import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notice.dart';
import '../../screens/notice_detail_screen.dart';
import '../common/custom_loading_indicator.dart';
import '../common/bounceable.dart'; // Toss-style Interaction

class HotNoticeWidget extends StatefulWidget {
  final bool forceShow;

  const HotNoticeWidget({super.key, this.forceShow = false});

  @override
  State<HotNoticeWidget> createState() => _HotNoticeWidgetState();
}

class _HotNoticeWidgetState extends State<HotNoticeWidget> {
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
          .orderBy('views_today', descending: true)
          .limit(5)
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _noticesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CustomLoadingIndicator());

        final notices = snapshot.data!.docs
            .map((doc) => Notice.fromFirestore(doc, []))
            .toList();

        if (notices.isEmpty) {
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
                      const Icon(
                        Icons.whatshot_rounded,
                        color: Color(0xFFFF5252),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "HOT 공지",
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
                      "아직은 HOT 공지가 없어요",
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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.whatshot_rounded,
                      color: Color(0xFFFF5252),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "HOT 공지",
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
              Column(
                children: notices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final notice = entry.value;
                  final isLast = index == notices.length - 1;
                  return Column(
                    children: [
                      Bounceable(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NoticeDetailScreen(notice: notice),
                            ),
                          );
                        },
                        borderRadius: isLast
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(24),
                              )
                            : BorderRadius.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          // onTap 제거
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
            ],
          ),
        );
      },
    );
  }
}
