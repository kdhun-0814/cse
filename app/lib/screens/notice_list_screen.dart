import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/firestore_service.dart';
import 'notice_detail_screen.dart';
import '../widgets/common/custom_loading_indicator.dart';
import '../widgets/common/bounceable.dart'; // Toss-style Interaction
import '../widgets/common/custom_dialog.dart';
import '../widgets/common/jelly_button.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // NEW
import '../utils/toast_utils.dart';
import 'admin/write_notice_screen.dart'; // NEW
import 'package:flutter/services.dart'; // Haptic Feedback

class NoticeListScreen extends StatefulWidget {
  final String title;
  final Color themeColor;

  const NoticeListScreen({
    super.key,
    required this.title,
    required this.themeColor,
  });

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  late Stream<List<Notice>> _noticeStream;
  String _searchQuery = "";
  final FocusNode _searchFocus = FocusNode(); // FocusNode 추가
  String _userRole = ''; // NEW

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() {}); // 포커스 변경 시 리빌드
    });
    _noticeStream = _firestoreService.getNotices(); // 스트림 초기화

    // 방문 기록 업데이트 (배지 초기화)
    if (widget.title != '전체') {
      _firestoreService.updateLastVisited(widget.title);
    }

    // 권한 가져오기
    _firestoreService.getUserRole().then((role) {
      if (mounted) {
        setState(() => _userRole = role);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.offset > 10) {
        if (!_isScrolled) setState(() => _isScrolled = true);
      } else {
        if (_isScrolled) setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F6),
        elevation: 0,
        scrolledUnderElevation: 0, // 스크롤 시 색상 변경 방지
        surfaceTintColor: Colors.transparent, // 틴트 컬러 제거
        shape: _isScrolled
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE5E8EB), width: 1),
              )
            : null,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF191F28),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
            fontSize: 18, // 15 -> 18 Increase font size
          ),
        ),
        actions: [
          // 1. 알림 토글 버튼 (모든 유저, 전체 카테고리 제외)
          if (widget.title != "전체")
            StreamBuilder<bool>(
              stream: _firestoreService.getCategoryPushSetting(widget.title),
              builder: (context, snapshot) {
                bool isEnabled = snapshot.data ?? true;
                return IconButton(
                  onPressed: () {
                    _firestoreService.toggleCategoryPushSetting(
                      widget.title,
                      !isEnabled,
                    );
                    ToastUtils.show(
                      context,
                      !isEnabled
                          ? "${widget.title} 알림이 켜졌어요."
                          : "${widget.title} 알림이 꺼졌어요.",
                    );
                  },
                  icon: Icon(
                    isEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: isEnabled
                        ? widget.themeColor
                        : const Color(0xFFB0B8C1),
                  ),
                );
              },
            ),

          // 2. 관리자용 글쓰기 버튼
          if (_userRole == 'ADMIN') ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WriteNoticeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, color: Color(0xFF191F28)),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            color: const Color(0xFFF2F4F6),
            child: Row(
              children: [
                Expanded(
                  child: Bounceable(
                    onTap: () {
                      HapticFeedback.lightImpact(); // 짧은 진동
                      _searchFocus.requestFocus(); // 터치 시 포커스 요청
                    },
                    immediate: true, // 즉시 실행
                    scaleFactor: 0.98, // 미세한 반응
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _searchFocus.hasFocus
                              ? const Color(0xFF3182F6) // Brand Color
                              : const Color(0xFFE5E8EB),
                          width: _searchFocus.hasFocus ? 2 : 1, // 두께 강조
                        ),
                      ),
                      child: TextField(
                        focusNode: _searchFocus, // FocusNode 연결
                        cursorColor: const Color(0xFF3182F6), // 커서 색상 변경
                        onTap: () {
                          HapticFeedback.lightImpact(); // 짧은 진동
                        },
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: "제목 또는 내용으로 검색해보세요",
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF8B95A1),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 리스트
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: _noticeStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoadingIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("에러 발생: ${snapshot.error}"));
                }

                final allNotices = snapshot.data ?? [];

                // 필터링 + 검색 로직
                List<Notice> filteredNotices = allNotices.where((n) {
                  // 1. 카테고리 필터
                  bool categoryMatch;
                  if (widget.title == '전체') {
                    categoryMatch = true;
                  } else if (widget.title == '긴급 공지') {
                    categoryMatch = n.isUrgent ?? false;
                  } else if (widget.title == '중요 공지') {
                    categoryMatch = n.isImportant ?? false;
                  } else {
                    categoryMatch =
                        n.category == widget.title ||
                        widget.title.contains(n.category);
                  }

                  if (!categoryMatch) return false;

                  // 2. 검색어 필터 (제목+내용)
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    final titleMatch = n.title.toLowerCase().contains(query);
                    final contentMatch = n.content.toLowerCase().contains(
                      query,
                    );
                    // content HTML이라 정확한 검색은 아닐 수 있지만 포함 여부는 확인 가능
                    return titleMatch || contentMatch;
                  }

                  return true;
                }).toList();

                // 정렬 로직: 스크랩된 공지 상단 고정 (스크랩 여부 -> 날짜 내림차순)
                filteredNotices.sort((a, b) {
                  if (a.isScraped != b.isScraped) {
                    return a.isScraped ? -1 : 1; // 스크랩된 것이 위로
                  }
                  // 스크랩 여부가 같으면 날짜 내림차순 (문자열 비교 YYYY.MM.DD)
                  return b.date.compareTo(a.date);
                });

                if (filteredNotices.isEmpty) {
                  return const Center(
                    child: Text(
                      "검색 결과가 없어요.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredNotices.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildListItem(filteredNotices[index]);
                  },
                );
              },
            ),
          ),
        ],
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

  Widget _buildListItem(Notice notice) {
    final card = Bounceable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticeDetailScreen(notice: notice),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E8EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  notice.date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8B95A1),
                  ),
                ),
                const Spacer(),
                JellyButton(
                  isActive: notice.isScraped,
                  activeIcon: Icons.bookmark_rounded,
                  inactiveIcon: Icons.bookmark_border_rounded,
                  activeColor: const Color(0xFFFFD180),
                  inactiveColor: const Color(0xFFD1D6DB),
                  onTap: () {
                    _firestoreService.toggleNoticeScrap(
                      notice.id,
                      notice.isScraped,
                    );
                    ToastUtils.show(
                      context,
                      !notice.isScraped ? "스크랩 보관함에 저장되었어요." : "스크랩이 해제되었어요.",
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notice.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191F28),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(notice.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    notice.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getCategoryColor(notice.category),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (notice.isUrgent == true) ...[
                  const SizedBox(width: 6),
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
                        fontSize: 11,
                        color: Color(0xFFD32F2F), // Strong Red
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  notice.author.isNotEmpty ? notice.author : "학과사무실",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B95A1),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.remove_red_eye_rounded,
                  size: 14,
                  color: Color(0xFFB0B8C1),
                ),
                const SizedBox(width: 4),
                Text(
                  "${notice.views}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B95A1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // 관리자가 아니면 그냥 카드 반환
    if (_userRole != 'ADMIN') {
      return card;
    }

    // 관리자면 슬라이드 기능 추가
    return Slidable(
      key: Key(notice.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) async {
              // 삭제 확인 다이얼로그
              bool confirm =
                  await showDialog(
                    context: context,
                    builder: (context) => CustomDialog(
                      title: "공지 삭제",
                      contentText: "정말로 이 공지를 삭제하시겠습니까?",
                      cancelText: "취소",
                      confirmText: "삭제",
                      isDestructive: true,
                      onConfirm: () => Navigator.pop(context, true),
                      onCancel: () => Navigator.pop(context, false),
                    ),
                  ) ??
                  false;

              if (confirm) {
                await _firestoreService.deleteNotice(notice.id);
                if (mounted) {
                  ToastUtils.show(context, "삭제되었습니다.");
                }
              }
            },
            backgroundColor: const Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: card,
    );
  }
}
