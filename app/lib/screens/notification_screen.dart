import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/notice.dart';
import 'notice_detail_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/common/bounceable.dart';
import '../widgets/common/custom_dialog.dart';
import '../utils/toast_utils.dart';

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
                builder: (ctx) => CustomDialog(
                  title: "모두 읽음 처리",
                  contentText: "모든 알림을 읽음 상태로 변경할까요?",
                  cancelText: "취소",
                  confirmText: "확인",
                  onCancel: () => Navigator.pop(ctx, false),
                  onConfirm: () => Navigator.pop(ctx, true),
                ),
              );

              if (confirm == true) {
                await _firestoreService.markAllGlobalNoticesAsRead();
                if (mounted) {
                  ToastUtils.show(context, "모두 읽음 처리되었어요.");
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
                      "아직 새로운 알림이 없어요.",
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
                      "검색 결과가 없어요.",
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
      child: Bounceable(
        onTap: () {
          // 상세 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoticeDetailScreen(notice: notice),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
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
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "긴급":
        return Colors.red[700]!;
      case "학사":
        return Colors.blue[700]!;
      case "장학":
        return Colors.orange[700]!;
      case "취업":
        return Colors.green[700]!;
      case "학과행사":
        return Colors.purple[700]!;
      case "외부행사":
        return Colors.grey[700]!;
      case "공모전":
        return Colors.amber[700]!;
      default:
        return const Color(0xFF3182F6);
    }
  }

  Widget _buildIcon(Notice notice) {
    // 긴급 -> 빨간 확성기
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
    // 중요 -> 노란 별 (추가 제안)
    if (notice.isImportant == true) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1), // Amber 50
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.star_rounded,
          color: Color(0xFFFFD180), // Amber 200~300
          size: 24,
        ),
      );
    }
    // 일반 -> 회색 종
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 카테고리 스티커 (컬러 적용)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(notice.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            notice.category,
            style: TextStyle(
              color: _getCategoryColor(notice.category),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // 2. 긴급 스티커
        if (notice.isUrgent == true) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), // Red 50
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "긴급",
              style: TextStyle(
                color: Color(0xFFD32F2F), // Red 700
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],

        // 3. 중요 스티커
        if (notice.isImportant == true) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // Amber 50
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "중요",
              style: TextStyle(
                color: Color(0xFFFFA000), // Amber 700
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
