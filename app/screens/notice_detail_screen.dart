import 'package:flutter/material.dart';
import '../models/notice.dart'; // 데이터 모델 import

class NoticeDetailScreen extends StatefulWidget {
  final Notice notice; // 어떤 공지인지 데이터를 받음

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  // 화면 안에서 스크랩 상태가 바뀌면 UI를 다시 그리기 위해
  late bool isScraped;

  @override
  void initState() {
    super.initState();
    isScraped = widget.notice.isScraped;
  }

  void _toggleScrap() {
    setState(() {
      isScraped = !isScraped;
      widget.notice.isScraped = isScraped; // 실제 데이터 원본도 수정
    });

    // 스크랩 여부에 따라 하단 스낵바 메시지 띄우기 (선택사항)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isScraped ? "스크랩함에 저장되었어요!" : "스크랩이 해제되었어요."),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF191F28)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 스크랩 버튼
          IconButton(
            icon: Icon(
              isScraped ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isScraped ? const Color(0xFFFFD180) : const Color(0xFFB0B8C1), // 노란색 vs 회색
              size: 28,
            ),
            onPressed: _toggleScrap,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 카테고리 & 날짜
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.notice.category,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4E5968), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.notice.date,
                  style: const TextStyle(color: Color(0xFF8B95A1), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. 제목
            Text(
              widget.notice.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF191F28), height: 1.4),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFF2F4F6)),
            const SizedBox(height: 24),

            // 3. 이미지 (있을 경우에만 표시)
            if (widget.notice.imageUrls.isNotEmpty)
              Column(
                children: widget.notice.imageUrls.map((url) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[100], // 로딩 전 배경색
                      image: DecorationImage(
                        image: NetworkImage(url), // 인터넷 이미지 불러오기
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),

            // 4. 본문 내용
            Text(
              widget.notice.content,
              style: const TextStyle(fontSize: 16, color: Color(0xFF333D4B), height: 1.6),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}