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
  // Show 3 items at once (1 / 3 = 0.333...)
  final PageController _pageController = PageController(
    viewportFraction: 0.333,
  );

  Timer? _timer;
  List<Notice> _cachedNotices = [];
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
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int totalItems) {
    _timer?.cancel();
    if (totalItems <= 3) return; // Scroll only if > 3 items

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
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

        // Auto-scroll logic if more than 3 items
        if (displayNotices.length > 3) {
          if (_cachedNotices.length != displayNotices.length) {
            _cachedNotices = displayNotices;
            _startAutoScroll(displayNotices.length);
          }
        } else {
          _timer?.cancel(); // Stop timer if items reduced to <= 3
        }

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
                child: displayNotices.length <= 3
                    ? Column(
                        children: displayNotices.map((notice) {
                          return _buildNoticeItem(context, notice);
                        }).toList(),
                      )
                    : SizedBox(
                        height: 52.0 * 3, // Total height for 3 items
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          padEnds: false, // Align content to top
                          scrollDirection: Axis.vertical,
                          // infinite scroll (no itemCount)
                          itemBuilder: (context, index) {
                            final realIndex = index % displayNotices.length;
                            return _buildNoticeItem(
                              context,
                              displayNotices[realIndex],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoticeItem(BuildContext context, Notice notice) {
    return SizedBox(
      height: 52, // Fixed height for alignment
      child: Bounceable(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoticeDetailScreen(notice: notice),
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 0,
          ),
          visualDensity: const VisualDensity(vertical: -4), // Compact
          // onTap 제거 (Bounceable에서 처리)
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
      ),
    );
  }
}
