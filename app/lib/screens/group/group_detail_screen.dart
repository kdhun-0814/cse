import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/group.dart';
import '../../services/firestore_service.dart'; // 서비스 임포트
import '../../utils/toast_utils.dart';
import '../../widgets/common/jelly_button.dart';
import '../../widgets/common/custom_loading_indicator.dart'; // 로딩 인디케이터 임포트
import '../../widgets/common/custom_dialog.dart';
import '../../widgets/common/bounceable.dart'; // Toss-style Interaction
import 'group_edit_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService(); // 서비스 인스턴스
  final _qnaController = TextEditingController();
  late bool _isLiked; // 로컬 상태 변수 (낙관적 업데이트용)
  bool _isScrolled = false; // 스크롤 상태

  // Advanced QnA States
  bool _isAnonymous = false;
  String? _replyToId; // 답변 중인 부모 ID
  String? _editingQnaId; // 수정 중인 글 ID

  @override
  void initState() {
    super.initState();
    _isLiked = widget.group.isLiked;
  }

  // --- 기능 함수들 (DB 연동) ---

  // ... (closeGroup, deleteGroup, openExternalLink 생략 - 변경없음) ...

  // 1. 모집 마감
  void _closeGroup() {
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "모집 마감",
        contentText: "정말 모집을 마감할까요?",
        cancelText: "취소",
        confirmText: "마감하기",
        isDestructive: true,
        onConfirm: () async {
          await _firestoreService.closeGroup(widget.group.id);
          if (mounted) {
            Navigator.pop(ctx);
            Navigator.pop(context); // 목록으로 돌아감
            ToastUtils.show(context, "모집이 마감되었어요.");
          }
        },
      ),
    );
  }

  // 2. 모집 삭제
  void _deleteGroup() {
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "모집 삭제",
        contentText: "정말로 이 글을 삭제할까요?\n삭제 후에는 복구할 수 없어요.",
        cancelText: "취소",
        confirmText: "삭제하기",
        isDestructive: true,
        onConfirm: () async {
          await _firestoreService.deleteGroup(widget.group.id);
          if (mounted) {
            Navigator.pop(ctx);
            Navigator.pop(context); // 목록으로 돌아감
            ToastUtils.show(context, "모집이 삭제되었어요.");
          }
        },
      ),
    );
  }

  // 3. 외부 링크 열기 (Group 객체를 받아 최신 링크 사용)
  void _openExternalLink(Group group) {
    if (group.linkUrl == null || group.linkUrl!.isEmpty) {
      ToastUtils.show(context, "신청 링크가 등록되지 않은 모임입니다.", isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "외부 폼 신청",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("아래 링크로 이동하여 신청서를 작성해주세요."),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                group.linkUrl!,
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        confirmText: "확인",
        onConfirm: () => Navigator.pop(ctx),
      ),
    );
  }

  // 4. QnA 등록/수정
  Future<void> _submitQnA() async {
    if (_qnaController.text.trim().isEmpty) return;

    if (_editingQnaId != null) {
      // 수정 모드
      await _firestoreService.updateQnA(
        widget.group.id,
        _editingQnaId!,
        _qnaController.text.trim(),
      );
      ToastUtils.show(context, "수정되었습니다.");
    } else {
      // 신규 등록 (질문 or 답변)
      await _firestoreService.addQnA(
        groupId: widget.group.id,
        content: _qnaController.text.trim(),
        isAnonymous: _isAnonymous,
        replyToId: _replyToId,
      );
      ToastUtils.show(
        context,
        _replyToId != null ? "답변이 등록되었어요." : "질문이 등록되었어요.",
      );
    }

    _resetQnAState();
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
    }
  }

  void _resetQnAState() {
    _qnaController.clear();
    _isAnonymous = false;
    _replyToId = null;
    _editingQnaId = null;
  }

  void _showQnADialog({
    String? initialContent,
    String? replyToId,
    String? editingId,
  }) {
    // 초기화 및 상태 설정
    _qnaController.text = initialContent ?? "";
    _replyToId = replyToId;
    _editingQnaId = editingId;
    // 수정 시에는 익명 여부 변경 불가 (기존 값 유지해야 하지만 편의상 수정 시엔 체크박스 숨기거나 비활성)
    // 여기선 단순화하여 수정 시 익명 체크박스 비활성화 처리 또는 기존 값 불러오기 필요.
    // 하지만 QnAItem에서 isAnonymous를 가져와야 함. 일단 기본값 or 기존 로직.

    // 답변 모드일 때 익명 체크는? 원글이 익명이면 답변도 익명 선호? -> 사용자 선택.

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // 다이얼로그 내부 상태(체크박스) 갱신용
          builder: (context, setDialogState) {
            String title = "질문 남기기";
            if (editingId != null)
              title = "수정하기";
            else if (replyToId != null)
              title = "답변 남기기";

            return CustomDialog(
              title: title,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _qnaController,
                    cursorColor: const Color(0xFF3182F6),
                    decoration: InputDecoration(
                      hintText: replyToId != null
                          ? "답변 내용을 입력해주세요."
                          : "궁금한 내용이 있으신가요?",
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF3182F6),
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  if (editingId == null) // 수정 아닐 때만 익명 선택 가능
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _isAnonymous,
                            activeColor: const Color(0xFF3182F6),
                            onChanged: (val) {
                              setDialogState(() {
                                _isAnonymous = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text("익명으로 남기기"),
                      ],
                    ),
                ],
              ),
              cancelText: "취소",
              confirmText: editingId != null ? "수정" : "등록",
              onConfirm: _submitQnA,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ★ 전체 화면을 StreamBuilder로 감싸서 실시간 업데이트 반영
    return StreamBuilder<Group>(
      stream: _firestoreService.getGroupStream(widget.group.id),
      initialData: widget.group,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CustomLoadingIndicator()));
        }

        final group = snapshot.data!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: _isScrolled
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFE5E8EB), width: 1),
                  )
                : null,
            leading: const BackButton(color: Colors.black),
            title: const Text(
              "모집 상세",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // 작성자 본인이면 수정 버튼 표시
              if (group.isMyGroup)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF3182F6),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupEditScreen(group: group),
                        ),
                      );
                    },
                  ),
                ),
              // 상단 찜(하트) 버튼 - DB 연동
              JellyButton(
                isActive: _isLiked, // 애니메이션을 위해 로컬 상태 사용
                enabled: !group.isExpired, // 마감된 경우 비활성화
                activeIcon: Icons.favorite_rounded,
                inactiveIcon: Icons.favorite_border_rounded,
                activeColor: const Color(0xFFFF4E4E),
                inactiveColor: const Color(0xFFB0B8C1),
                onTap: () async {
                  setState(() {
                    _isLiked = !_isLiked; // 낙관적 업데이트
                  });
                  // ★ 찜 상태 토글 및 DB 반영
                  await _firestoreService.toggleGroupLike(
                    group.id,
                    !_isLiked, // 이미 반전시켰으므로 원래 상태(반전 전)를 보낼지, 바뀐 상태를 보낼지 로직 확인.
                    // toggleGroupLike(id, currentStatus) -> 로직상 'currentStatus'를 보내면 반대로 바꿈.
                    // 위에서 _isLiked를 이미 바꿨으므로, 바뀐 상태(_isLiked)의 반대인 '이전 상태'를 보내야 함.
                    // 즉 !(_isLiked) == 원래 _isLiked 값.
                    // 아니면 그냥 toggleGroupLike 호출 전 _isLiked를 넘기면 됨.
                    // 복잡하니 아래와 같이 수정:
                  );
                  // 이미 setState 했으므로 추가 작업 불필요 (Stream이 오면 다시 그려짐)
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 문의하기 버튼 (플로팅)
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                final isScrolled = notification.metrics.pixels > 10;
                if (_isScrolled != isScrolled) {
                  setState(() {
                    _isScrolled = isScrolled;
                  });
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: group.hashtags
                        .map(
                          (tag) => Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF3182F6),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoItem(
                          "모집 인원",
                          group.maxMembers == -1
                              ? "제한 없음"
                              : "${group.maxMembers}명 모집",
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        _infoItem(
                          "마감일",
                          DateFormat('MM.dd').format(group.deadline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ★ 신청 링크 표시
                  if (group.linkUrl != null && group.linkUrl!.isNotEmpty) ...[
                    const Text(
                      "신청 링크",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Bounceable(
                      onTap: () => _openExternalLink(group),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E8EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.link,
                              size: 20,
                              color: Color(0xFF3182F6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                group.linkUrl!,
                                style: const TextStyle(
                                  color: Color(0xFF3182F6),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    "상세 내용",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF333D4B),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    "Q&A 게시판",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (group.qnaList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "아직 등록된 질문이 없어요.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    _buildQnAList(group.qnaList),

                  const SizedBox(height: 16),

                  // 문의하기 버튼 -> 코멘트 남기기 버튼 (토스 스타일 Bounceable 적용)
                  Center(
                    child: Bounceable(
                      onTap: () => _showQnADialog(),
                      borderRadius: BorderRadius.circular(20), // 오버레이 둥글기 맞춤
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: Color(0xFF3182F6),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "질문 남기기",
                              style: TextStyle(
                                color: Color(0xFF3182F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // 하단 버튼 (홈 하단 내비게이션 스타일 적용)
          bottomNavigationBar: Container(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E8EB), width: 1),
                left: BorderSide(color: Color(0xFFE5E8EB), width: 1),
                right: BorderSide(color: Color(0xFFE5E8EB), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: group.isMyGroup
                    ? Row(
                        children: [
                          Expanded(
                            child: Bounceable(
                              onTap: _deleteGroup,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E8EB)),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  "모집 삭제하기",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Bounceable(
                              onTap: group.isManuallyClosed ? null : _closeGroup,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E8EB)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  group.isManuallyClosed ? "마감완료" : "마감하기",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF191F28),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Bounceable(
                        onTap: group.isExpired
                            ? null
                            : () => _openExternalLink(group),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3182F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            group.isExpired
                                ? "이미 마감된 모집이에요."
                                : (group.linkUrl == null
                                      ? "신청 링크가 없어요."
                                      : "신청하러 가기 (외부 폼)"),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191F28),
          ),
        ),
      ],
    );
  }

  // QnA 리스트 구성 (쓰레드 방식)
  Widget _buildQnAList(List<QnAItem> items) {
    final roots = items.where((i) => i.replyToId == null).toList();
    final replies = items.where((i) => i.replyToId != null).toList();

    roots.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    List<Widget> widgetList = [];

    for (var root in roots) {
      widgetList.add(_buildQnAItem(root, isReply: false));
      final myReplies = replies.where((r) => r.replyToId == root.id).toList();
      for (var reply in myReplies) {
        widgetList.add(_buildQnAItem(reply, isReply: true));
      }
    }

    return Column(children: widgetList);
  }

  Widget _buildQnAItem(QnAItem item, {required bool isReply}) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = item.userId == currentUid;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 32 : 0, // 답글 들여쓰기
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // ★ 3번 수정: 상단 정렬 명시
        children: [
          if (isReply)
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 4),
              child: Icon(
                Icons.subdirectory_arrow_right,
                size: 16,
                color: Colors.grey,
              ),
            ),

          CircleAvatar(
            radius: 16,
            backgroundColor: isReply ? Colors.grey[100] : Colors.grey[200],
            child: Icon(
              Icons.person,
              size: 20,
              color: isMe ? const Color(0xFF3182F6) : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // 이름과 날짜는 중앙 정렬
                  children: [
                    Text(
                      item.isAnonymous
                          ? "익명${item.anonymousId ?? ''}"
                          : item.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: item.isAnonymous ? Colors.black87 : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MM.dd HH:mm').format(item.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    if (item.isEdited && !item.isDeleted)
                      Text(
                        " (수정됨)",
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    const Spacer(),

                    // ★ 5번 수정: 점 3개 메뉴 -> BottomSheet 스타일 통일
                    if (isMe && !item.isDeleted)
                      Bounceable(
                        onTap: () {
                          _showQnAMenu(item);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                item.isDeleted
                    ? const Text(
                        "삭제된 메시지입니다.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Container(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.content,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF333D4B),
                                height: 1.4,
                              ),
                            ),
                            if (!isReply && !item.isDeleted)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Bounceable(
                                  onTap: () {
                                    _showQnADialog(replyToId: item.id);
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 2,
                                    ),
                                    child: Text(
                                      "답변 달기",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQnAMenu(QnAItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: const Text("수정하기"),
                onTap: () {
                  Navigator.pop(context);
                  _showQnADialog(
                    initialContent: item.content,
                    editingId: item.id,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFFF4E4E)),
                title: const Text(
                  "삭제하기",
                  style: TextStyle(color: Color(0xFFFF4E4E)),
                ),
                onTap: () {
                  Navigator.pop(context); // 닫기
                  _confirmDeleteQnA(item); // 삭제 확인 창
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteQnA(QnAItem item) {
    // 답글인지 판단
    final isReply = item.replyToId != null;
    final type = isReply ? "답변" : "질문";

    showDialog(
      // ★ 기존 다이얼로그 스타일 유지
      context: context,
      builder: (ctx) => CustomDialog(
        title: "$type 삭제",
        contentText: "정말로 이 $type을 삭제할까요?",
        cancelText: "취소",
        confirmText: "삭제",
        isDestructive: true,
        onConfirm: () async {
          await _firestoreService.deleteQnA(
            widget.group.id,
            item.id,
          ); // Soft Delete
          if (mounted) {
            Navigator.pop(ctx);
            // 삭제된 메시지로 변경되므로 굳이 pop 안해도 됨 (UI 갱신)
            setState(() {});
          }
        },
      ),
    );
  }
}
