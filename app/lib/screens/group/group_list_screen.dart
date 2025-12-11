import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // ★ 재추가
import '../../models/group.dart';
import '../../services/firestore_service.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends StatefulWidget {
  final String filterType; // 'all', 'my', 'liked'

  const GroupListScreen({super.key, this.filterType = 'all'});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isAdmin = false;
  late Stream<List<Group>> _groupStream; // ★ 스트림 캐싱

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _groupStream = _firestoreService.getGroups(widget.filterType); // ★ 초기화
  }

  Future<void> _checkAdminRole() async {
    String role = await _firestoreService.getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = (role == 'ADMIN');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ★ StreamBuilder로 DB 데이터 감시
    return StreamBuilder<List<Group>>(
      stream: _groupStream, // ★ 캐싱된 스트림 사용
      builder: (context, snapshot) {
        // 1. 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3182F6)),
          );
        }
        // 2. 에러 발생
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "잠시 오류가 발생했어요.\n${snapshot.error}",
              textAlign: TextAlign.center,
            ),
          );
        }

        // 3. 데이터 없음 또는 빈 리스트
        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          String emptyMsg = "지금은 모집 중인 글이 없어요.";
          if (widget.filterType == 'my') emptyMsg = "내가 만든 모집이 없어요.";
          if (widget.filterType == 'liked') emptyMsg = "찜한 모집이 없어요.";

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMsg,
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
              ],
            ),
          );
        }

        // 4. 리스트 출력
        final allGroups = groups;

        // 필터링: 공식글과 일반글 분리 (전체 목록일 때만 분리)
        List<Group> officialGroups = [];
        List<Group> generalGroups = [];

        if (widget.filterType == 'all') {
          officialGroups = allGroups.where((g) => g.isOfficial).toList();
          generalGroups = allGroups.where((g) => !g.isOfficial).toList();
        } else {
          generalGroups = allGroups;
        }

        // ★ 정렬 로직 추가: 마감된 것은 맨 뒤로 (Partitioning)
        officialGroups = [
          ...officialGroups.where((g) => !g.isExpired),
          ...officialGroups.where((g) => g.isExpired),
        ];

        generalGroups = [
          ...generalGroups.where((g) => !g.isExpired),
          ...generalGroups.where((g) => g.isExpired),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          children: [
            // ★ 1. 공식(학생회) 섹션 (가로 스크롤)
            if (officialGroups.isNotEmpty) ...[
              SizedBox(
                height: 170, // 카드 높이 지정
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: officialGroups.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _buildOfficialCard(officialGroups[index]);
                  },
                ),
              ),
              const SizedBox(height: 24), // 섹션 간 간격
            ],

            // ★ 2. 일반 공고 리스트
            if (generalGroups.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    "등록된 모집이 없어요.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...generalGroups.map((group) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildGroupCard(group),
                );
              }).toList(),
          ],
        );
      },
    );
  }

  // ★ 공식 공고 카드 위젯
  Widget _buildOfficialCard(Group group) {
    bool isExpired = group.isExpired;
    return GestureDetector(
      onTap: isExpired
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailScreen(group: group),
                ),
              );
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Opacity(
          opacity: isExpired ? 0.6 : 1.0, // 전체 투명도 적용
          child: Container(
            width: 280, // 가로 고정 너비
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isExpired
                  ? Colors.grey[200] // 마감 시 회색 배경
                  : const Color(0xFFE8F3FF), // 활성 시 파란 배경
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpired
                    ? Colors.grey[300]!
                    : const Color(
                        0xFF3182F6,
                      ).withOpacity(0.3), // ★ 다시 파란색 보더로 복구
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors
                                  .grey // 마감 시 회색 뱃지
                            : const Color(0xFF3182F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "학생회",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      group.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isExpired
                            ? Colors.grey[600] // 마감 시 회색 텍스트
                            : const Color(0xFF191F28),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: isExpired
                          ? Colors
                                .grey // 마감 시 회색 아이콘
                          : const Color(0xFF3182F6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExpired
                          ? "마감됨"
                          : "D-${group.deadline.difference(DateTime.now()).inDays}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isExpired
                            ? Colors
                                  .grey // 마감 시 회색 텍스트
                            : const Color(0xFF3182F6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    bool isExpired = group.isExpired;

    return Slidable(
      key: Key(group.id),
      enabled: _isAdmin, // 관리자만 슬라이드 가능
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              _confirmDelete(group);
            },
            backgroundColor: const Color(0xFFEF9A9A),
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(20),
            // CustomSlidableAction does not support 'icon' or 'label' directly with border,
            // but we can use 'child' to render them. However, usually CustomSlidableAction
            // is used when we want full control.
            // Actually, SlidableAction might maintain internal layout.
            // Let's try wrapping the icon and label in a Column centered.
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E8EB)), // 회색 보더 추가
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete, size: 28),
                  SizedBox(height: 4),
                  Text("삭제 (관리자)", style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: isExpired
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupDetailScreen(group: group),
                  ),
                );
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Opacity(
            opacity: isExpired ? 0.7 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isExpired ? Colors.grey[200] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isExpired
                      ? Colors.transparent
                      : const Color(0xFFE5E8EB), // ★ 보더 추가
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 제목 & 찜 버튼
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          group.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191F28),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // ★ DB 찜 토글 호출
                          _firestoreService.toggleGroupLike(
                            group.id,
                            group.isLiked,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Icon(
                            group.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: group.isLiked
                                ? const Color(0xFFFF4E4E)
                                : const Color(0xFFB0B8C1),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 2. 해시태그
                  Wrap(
                    spacing: 6,
                    children: group.hashtags
                        .map(
                          (tag) => Text(
                            tag,
                            style: TextStyle(
                              color: isExpired
                                  ? Colors.grey
                                  : const Color(0xFF3182F6),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // 3. 정보 (인원, 마감일)
                  Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        group.maxMembers == -1
                            ? "제한 없음"
                            : "${group.maxMembers}명 모집",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 10, color: Colors.grey[300]),
                      const SizedBox(width: 12),
                      Text(
                        isExpired
                            ? "마감됨"
                            : "D-${group.deadline.difference(DateTime.now()).inDays}",
                        style: TextStyle(
                          color: isExpired
                              ? Colors.grey
                              : const Color(0xFFFF4E4E),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 삭제 확인 다이얼로그 (별도 메서드)
  void _confirmDelete(Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("관리자 권한으로 삭제"),
        content: const Text("정말로 이 모집글을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteGroup(group.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("모집이 삭제되었습니다.")));
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
