import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/notice.dart';
import 'notice_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text(
          "알림 센터",
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF191F28)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.playlist_add_check_rounded,
              color: Color(0xFF191F28),
            ),
            tooltip: "모두 읽음 처리",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("모두 읽음 처리"),
                  content: const Text("모든 알림을 읽음 상태로 변경하시겠습니까?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        "취소",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        "확인",
                        style: TextStyle(color: Color(0xFF3182F6)),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _firestoreService.markAllGlobalNoticesAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("모두 읽음 처리되었습니다.")),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "알림 검색...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB0B8C1)),
                filled: true,
                fillColor: const Color(0xFFF2F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E8EB)),

          // 알림 리스트
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: _firestoreService.getGlobalRecentNotices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "새로운 알림이 없습니다.",
                      style: TextStyle(color: Color(0xFF8B95A1)),
                    ),
                  );
                }

                // 필터링
                final notices = snapshot.data!.where((n) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return n.title.toLowerCase().contains(q) ||
                      n.content.toLowerCase().contains(q) ||
                      n.category.toLowerCase().contains(q);
                }).toList();

                if (notices.isEmpty) {
                  return const Center(
                    child: Text(
                      "검색 결과가 없습니다.",
                      style: TextStyle(color: Color(0xFF8B95A1)),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: notices.length,
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    return _buildNotificationCard(context, notice);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Notice notice) {
    // 읽음 여부에 따른 스타일
    final bool isUnread = !notice.isRead;

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFE8F3FF) : Colors.white, // 안 읽음: 연한 파랑
        borderRadius: BorderRadius.circular(16),
        border: isUnread
            ? Border.all(color: const Color(0xFF3182F6), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // 상세 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoticeDetailScreen(notice: notice),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아이콘 (카테고리별 or 긴급)
                _buildIcon(notice),
                const SizedBox(width: 16),
                // 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCategoryTag(notice),
                          Text(
                            notice.date,
                            style: TextStyle(
                              color: isUnread
                                  ? const Color(0xFF3182F6)
                                  : const Color(0xFF8B95A1),
                              fontSize: 12,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notice.title,
                        style: TextStyle(
                          color: const Color(0xFF191F28),
                          fontSize: 16,
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notice.content,
                        style: const TextStyle(
                          color: Color(0xFF4E5968),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Notice notice) {
    if (notice.isUrgent == true) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.campaign_rounded,
          color: Color(0xFFFF4848),
          size: 24,
        ),
      );
    }
    // 일반 공지 아이콘
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.notifications_outlined,
        color: Color(0xFFB0B8C1),
        size: 24,
      ),
    );
  }

  Widget _buildCategoryTag(Notice notice) {
    if (notice.isUrgent == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4848),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          "긴급 공지",
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        notice.category,
        style: const TextStyle(
          color: Color(0xFF4E5968),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
