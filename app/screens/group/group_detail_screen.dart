import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/group.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  // --- 기능 함수들 (기존 로직 동일) ---
  void _closeGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("모집 마감"),
        content: const Text("정말로 모집을 마감하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(
            onPressed: () {
              setState(() {
                widget.group.isManuallyClosed = true;
              });
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("마감하기", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("모집글 삭제"),
        content: const Text("정말로 이 글을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(
            onPressed: () {
              // 실제 삭제 로직
              // dummyGroups.remove(widget.group); 
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("삭제하기", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openExternalLink() {
    if (widget.group.linkUrl == null || widget.group.linkUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("신청 링크가 등록되지 않은 모임입니다.")));
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
            const SizedBox(height:10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: SelectableText(widget.group.linkUrl!, style:const TextStyle(color:Colors.blue)),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인")) 
        ],
      ),
    );
  }

  void _submitQuestion() {
    if (_questionController.text.isEmpty) return;
    setState(() {
      widget.group.qnaList.add(QnA(question: _questionController.text, questionerName: "익명"));
      _questionController.clear();
    });
    Navigator.pop(context); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("질문이 등록되었습니다.")));
  }

  void _showQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("문의하기"),
        content: TextField(
          controller: _questionController,
          decoration: const InputDecoration(hintText: "궁금한 점을 물어보세요", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          ElevatedButton(onPressed: _submitQuestion, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3182F6)), child: const Text("등록")),
        ],
      ),
    );
  }

  void _submitAnswer(QnA qna) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("답변 작성"),
        content: TextField(controller: _answerController, decoration: const InputDecoration(hintText: "답변을 입력하세요")),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                qna.answer = _answerController.text;
                _answerController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text("등록"),
          )
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
        leading: const BackButton(color: Colors.black),
        title: const Text("모집 상세", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          // 상단 찜(하트) 버튼
          IconButton(
            onPressed: () {
              setState(() {
                widget.group.isLiked = !widget.group.isLiked;
              });
            },
            icon: Icon(
              widget.group.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: widget.group.isLiked ? const Color(0xFFFF4E4E) : const Color(0xFFB0B8C1),
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
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF3182F6)),
              label: const Text("문의하기", style: TextStyle(color: Color(0xFF3182F6), fontWeight: FontWeight.bold)),
              elevation: 4,
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: widget.group.hashtags.map((tag) => Text(tag, style: const TextStyle(color: Color(0xFF3182F6), fontSize: 13, fontWeight: FontWeight.w600))).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF2F4F6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoItem("모집 인원", "${widget.group.maxMembers}명 모집"),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  _infoItem("마감일", DateFormat('MM.dd').format(widget.group.deadline)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("상세 내용", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.group.content, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF333D4B))),
            const SizedBox(height: 40),
            const Text("문의 / 질문", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (widget.group.qnaList.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("아직 등록된 질문이 없습니다.", style: TextStyle(color: Colors.grey))),
            ...widget.group.qnaList.map((qna) => _buildQnaItem(qna)).toList(),
            const SizedBox(height: 80), 
          ],
        ),
      ),
      
      // ★ 하단 버튼 수정: 흰색 배경 적용
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: widget.group.isMyGroup
              ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _deleteGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // 흰색 배경
                          foregroundColor: Colors.red,   // 빨간 글씨
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E8EB)), // 연한 회색 테두리
                          )
                        ),
                        child: const Text("공지 내리기", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.group.isManuallyClosed ? null : _closeGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // 흰색 배경
                          foregroundColor: const Color(0xFF191F28), // 검정 글씨
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E8EB)), // 연한 회색 테두리
                          )
                        ),
                        child: Text(widget.group.isManuallyClosed ? "마감완료" : "마감하기", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: widget.group.isExpired ? null : _openExternalLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3182F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.group.isExpired 
                      ? "마감된 모임입니다" 
                      : (widget.group.linkUrl == null ? "신청 링크가 없습니다" : "신청하러 가기 (외부 폼)"),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) { return Column(children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF191F28)))]); }
  
  Widget _buildQnaItem(QnA qna) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.help, size: 16, color: Colors.orange), const SizedBox(width: 8), Expanded(child: Text(qna.question, style: const TextStyle(fontWeight: FontWeight.w600)))]),
          if (qna.answer != null) ...[const SizedBox(height: 8), Row(children: [const Icon(Icons.check_circle, size: 16, color: Color(0xFF3182F6)), const SizedBox(width: 8), Expanded(child: Text(qna.answer!, style: const TextStyle(color: Color(0xFF3182F6))))])],
          if (widget.group.isMyGroup && qna.answer == null) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _submitAnswer(qna), child: const Text("답변하기", style: TextStyle(fontSize: 12))))
      ]),
    );
  }
}