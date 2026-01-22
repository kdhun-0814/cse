import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';
import '../services/firestore_service.dart';
import 'notice_detail_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // NEW
import 'admin/write_notice_screen.dart'; // NEW

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
  String _userRole = ''; // NEW

  @override
  void initState() {
    super.initState();
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
          // 0. 푸시 알림 전송 버튼 (관리자 전용, 카테고리별)
          if (_userRole == 'ADMIN' &&
              widget.title != '전체' &&
              widget.title != '긴급 공지' &&
              widget.title != '중요 공지')
            IconButton(
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF191F28),
              ),
              tooltip: "${widget.title} 푸시 전송",
              onPressed: () async {
                // Get the latest notice from this category
                final snapshot = await FirebaseFirestore.instance
                    .collection('notices')
                    .where('category', isEqualTo: widget.title)
                    .orderBy('date', descending: true)
                    .limit(1)
                    .get();

                if (snapshot.docs.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("공지가 없습니다.")));
                  }
                  return;
                }

                final noticeId = snapshot.docs.first.id;
                final noticeTitle = snapshot.docs.first.data()['title'] ?? '';

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text("${widget.title} 푸시 알림"),
                    content: Text(
                      "'$noticeTitle'\n\n이 공지에 대한 푸시 알림을 전송하시겠습니까?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
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
                  await _firestoreService.requestPushNotification(noticeId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("푸시 알림 요청이 전송되었습니다.")),
                    );
                  }
                }
              },
            ),

          // 1. 모두 읽음 처리 버튼 (카테고리 뷰일 때만)
          if (widget.title != '전체' &&
              widget.title != '긴급 공지' &&
              widget.title != '중요 공지')
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
                    title: Text("'${widget.title}' 공지 모두 읽음"),
                    content: const Text("전체 공지를\n모두 읽음 처리하시겠습니까?"),
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
                  await _firestoreService.markAllNoticesAsRead(widget.title);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("모두 읽음 처리되었습니다."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
            ),

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
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isEnabled
                              ? "${widget.title} 알림이 켜졌어요."
                              : "${widget.title} 알림이 꺼졌어요.",
                        ),
                        duration: const Duration(milliseconds: 1000),
                        behavior: SnackBarBehavior.floating,
                      ),
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
                // 검색 타입 선택 (간소화)
                // 공간 문제로 드롭다운 대신 아이콘이나 탭을 쓸 수 있지만,
                // 여기선 TextField 앞에 접두어로 둠.
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E8EB)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "제목 또는 내용으로 검색하세요.",
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
              ],
            ),
          ),

          // 리스트
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: _noticeStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
        return const Color(0xFFFF8A80);
      case "학사":
        return const Color(0xFF90CAF9);
      case "장학":
        return const Color(0xFFFFCC80);
      case "취업":
        return const Color(0xFFA5D6A7);
      case "학과행사":
        return const Color(0xFFCE93D8);
      case "외부행사":
        return const Color(0xFF9E9E9E);
      case "공모전":
        return const Color(0xFFFFEE58);
      case "광고":
        return const Color(0xFFB0BEC5);
      default:
        return const Color(0xFF3182F6);
    }
  }

  Widget _buildListItem(Notice notice) {
    final card = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticeDetailScreen(notice: notice),
          ),
        );
      },
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
                GestureDetector(
                  onTap: () {
                    _firestoreService.toggleNoticeScrap(
                      notice.id,
                      notice.isScraped,
                    );
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !notice.isScraped
                              ? "스크랩 보관함에 저장되었어요."
                              : "스크랩이 해제되었어요.",
                        ),
                        duration: const Duration(milliseconds: 1000),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Icon(
                    notice.isScraped
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 24,
                    color: notice.isScraped
                        ? const Color(0xFFFFD180)
                        : const Color(0xFFD1D6DB),
                  ),
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
                    builder: (context) => AlertDialog(
                      title: const Text("공지 삭제"),
                      content: const Text("정말로 이 공지를 삭제하시겠습니까?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("취소"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "삭제",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (confirm) {
                await _firestoreService.deleteNotice(notice.id);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
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
