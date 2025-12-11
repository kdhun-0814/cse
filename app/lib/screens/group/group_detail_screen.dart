import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/group.dart';
import '../../services/firestore_service.dart'; // 서비스 임포트

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService(); // 서비스 인스턴스
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  late bool _isLiked; // ★ 로컬 상태 변수
  bool _isScrolled = false; // 스크롤 상태

  @override
  void initState() {
    super.initState();
    _isLiked = widget.group.isLiked;
  }

  // --- 기능 함수들 (DB 연동) ---

  // 1. 모집 마감
  void _closeGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("모집 마감"),
        content: const Text("정말 모집을 마감할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              // ★ DB 업데이트 호출
              await _firestoreService.closeGroup(widget.group.id);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context); // 목록으로 돌아감
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("모집이 마감되었어요.")));
              }
            },
            child: const Text("마감하기", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 2. 모집 삭제
  void _deleteGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("모집 삭제"),
        content: const Text("정말로 이 글을 삭제할까요?\n삭제 후에는 복구할 수 없어요."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              // ★ DB 삭제 호출
              await _firestoreService.deleteGroup(widget.group.id);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context); // 목록으로 돌아감
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("모집이 삭제되었어요.")));
              }
            },
            child: const Text("삭제하기", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 3. 외부 링크 열기 (그대로 유지)
  void _openExternalLink() {
    if (widget.group.linkUrl == null || widget.group.linkUrl!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("신청 링크가 등록되지 않은 모임입니다.")));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("외부 폼 신청"),
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
                widget.group.linkUrl!,
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // 4. 질문 등록
  Future<void> _submitQuestion() async {
    if (_questionController.text.isEmpty) return;

    // ★ DB에 질문 추가
    await _firestoreService.addQuestion(
      widget.group.id,
      _questionController.text,
    );

    _questionController.clear();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("질문이 등록되었어요.")));
      // 화면 갱신을 위해 setState 호출 (필요시 StreamBuilder로 감싸는 것이 더 좋으나, 현재 구조상 팝업 닫히고 리스트 갱신됨)
      setState(() {});
    }
  }

  void _showQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("문의하기"),
        content: TextField(
          controller: _questionController,
          decoration: const InputDecoration(
            hintText: "궁금한 점을 물어보세요",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: _submitQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3182F6),
            ),
            child: const Text("등록"),
          ),
        ],
      ),
    );
  }

  // 5. 답변 작성 (추후 구현 - 현재 모델 구조상 복잡하여 일단 UI만 유지하거나 기능 보류)
  void _submitAnswer(QnA qna) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("답변 작성"),
        content: const Text("답변 기능은 현재 준비 중입니다."), // 간단하게 처리
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 상단 찜(하트) 버튼 - DB 연동
          // 상단 찜(하트) 버튼 - DB 연동
          IconButton(
            onPressed: () async {
              // ★ 찜 상태 토글 및 DB 반영
              await _firestoreService.toggleGroupLike(
                widget.group.id,
                _isLiked,
              );
              setState(() {
                _isLiked = !_isLiked; // UI 즉시 반영
              });
            },
            icon: Icon(
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isLiked
                  ? const Color(0xFFFF4E4E)
                  : const Color(0xFFB0B8C1),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // 문의하기 버튼 (플로팅)
      floatingActionButton: !widget.group.isMyGroup
          ? FloatingActionButton.extended(
              onPressed: _showQuestionDialog,
              backgroundColor: Colors.white,
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF3182F6),
              ),
              label: const Text(
                "문의하기",
                style: TextStyle(
                  color: Color(0xFF3182F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 4,
            )
          : null,

      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            // 빈번한 상태 변경 방지를 위해 threshold 적용 (10px)
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
                widget.group.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: widget.group.hashtags
                    .map(
                      (tag) => Text(
                        tag,
                        style: const TextStyle(
                          color: Color(0xFF3182F6),
                          fontSize: 13,
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
                      widget.group.maxMembers == -1
                          ? "제한 없음"
                          : "${widget.group.maxMembers}명 모집",
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    _infoItem(
                      "마감일",
                      DateFormat('MM.dd').format(widget.group.deadline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "상세 내용",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.group.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 40),

              // 질문 목록 (DB에서 실시간 반영이 되려면 StreamBuilder가 필요하지만,
              // 현재 구조에서는 리스트에서 넘어온 데이터를 보여주므로, 질문 작성 후 뒤로갔다 와야 보일 수 있음.
              // 완벽하게 하려면 이 부분도 StreamBuilder로 감싸야 합니다.)
              const Text(
                "문의 / 질문",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (widget.group.qnaList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "아직 등록된 질문이 없어요.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ...widget.group.qnaList.map((qna) => _buildQnaItem(qna)).toList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // 하단 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: widget.group.isMyGroup
              ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _deleteGroup, // 연동됨
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E8EB)),
                          ),
                        ),
                        child: const Text(
                          "모집 삭제하기",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.group.isManuallyClosed
                            ? null
                            : _closeGroup, // 연동됨
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF191F28),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E8EB)),
                          ),
                        ),
                        child: Text(
                          widget.group.isManuallyClosed ? "마감완료" : "마감하기",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: widget.group.isExpired ? null : _openExternalLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3182F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.group.isExpired
                        ? "이미 마감된 모집이에요."
                        : (widget.group.linkUrl == null
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
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

  Widget _buildQnaItem(QnA qna) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  qna.question,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (qna.answer != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF3182F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    qna.answer!,
                    style: const TextStyle(color: Color(0xFF3182F6)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
