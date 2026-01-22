import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notice.dart';
import '../../screens/notice_detail_screen.dart';
import '../../screens/notice_list_screen.dart';
import '../../services/firestore_service.dart';

class UrgentNoticeWidget extends StatefulWidget {
  final bool forceShow;

  const UrgentNoticeWidget({super.key, this.forceShow = false});

  @override
  State<UrgentNoticeWidget> createState() => _UrgentNoticeWidgetState();
}

class _UrgentNoticeWidgetState extends State<UrgentNoticeWidget> {
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _timer;
  int _currentPage = 0;
  List<Notice> _cachedNotices = [];
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await _firestoreService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int totalItems) {
    _timer?.cancel();
    if (totalItems <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('date', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final now = DateTime.now();
        final urgentNotices = snapshot.data!.docs
            .map((doc) => Notice.fromFirestore(doc, []))
            .where((n) {
              if (n.isUrgent != true) return false;
              try {
                String dateStr = n.date
                    .replaceAll('.', '-')
                    .replaceAll('/', '-')
                    .trim();
                DateTime? noticeDate = DateTime.tryParse(dateStr);
                if (noticeDate == null) {
                  List<String> parts = n.date.split('.');
                  if (parts.length >= 3) {
                    noticeDate = DateTime(
                      int.parse(parts[0].trim()),
                      int.parse(parts[1].trim()),
                      int.parse(parts[2].trim()),
                    );
                  }
                }
                if (noticeDate != null) {
                  final diff = now.difference(noticeDate).inDays;
                  return diff <= 14;
                }
              } catch (e) {}
              return false;
            })
            .toList();

        if (urgentNotices.isNotEmpty && _timer == null) {
          _startAutoScroll(urgentNotices.length);
        }

        if (urgentNotices.isEmpty) {
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
                        Icons.campaign_rounded,
                        color: Color(0xFFD32F2F),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "긴급 공지",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
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
                      "아직은 긴급 공지가 없어요",
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
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD32F2F).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFCDD2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: const Color(0xFFFFEBEE),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.campaign_rounded,
                          color: Color(0xFFD32F2F),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "긴급 공지",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_userRole == 'ADMIN' && urgentNotices.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFFD32F2F),
                              size: 20,
                            ),
                            tooltip: "긴급 공지 푸시 전송",
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("긴급 공지 푸시 알림"),
                                  content: const Text(
                                    "최신 긴급 공지에 대한 푸시 알림을 전송하시겠습니까?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text("취소"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("전송"),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                await _firestoreService.requestPushNotification(
                                  urgentNotices.first.id,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("푸시 알림 요청이 전송되었습니다."),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NoticeListScreen(
                                  title: "긴급 공지",
                                  themeColor: Color(0xFFD32F2F),
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "전체보기",
                            style: TextStyle(
                              color: const Color(0xFFD32F2F).withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: const Color(0xFFD32F2F).withOpacity(0.1),
              ),
              SizedBox(
                height: 140,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    final realIndex = index % urgentNotices.length;
                    return Padding(
                      padding: const EdgeInsets.all(0),
                      child: _buildUrgentContent(
                        context,
                        urgentNotices[realIndex],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUrgentContent(BuildContext context, Notice notice) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticeDetailScreen(notice: notice),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE), // Pastel Red
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "긴급",
                    style: TextStyle(
                      color: Color(0xFFD32F2F), // Strong Red
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notice.date.length > 5
                      ? notice.date.substring(5)
                      : notice.date,
                  style: TextStyle(
                    color: const Color(0xFFD32F2F).withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                notice.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191F28),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD32F2F),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
