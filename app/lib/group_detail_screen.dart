// lib/group_detail_screen.dart
import 'package:flutter/material.dart';

class GroupDetailScreen extends StatelessWidget {
  final String title;
  final List<String> tags;
  final String deadline;
  final int currentMember;
  final int maxMember;

  const GroupDetailScreen({
    super.key,
    required this.title,
    required this.tags,
    required this.deadline,
    required this.currentMember,
    required this.maxMember,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. 상단 앱바 (뒤로가기 버튼 자동 생성됨)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context), // 뒤로가기
        ),
        title: const Text(
          '모집 상세',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),

      // 2. 본문 내용
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 12),
            
            // 태그
            Wrap(
              spacing: 8,
              children: tags.map((tag) => Text(
                tag,
                style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.w500),
              )).toList(),
            ),
            const SizedBox(height: 30),

            // 회색 정보 박스 (인원 | 마감일)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8), // 아주 연한 회색 배경
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoColumn('모집 인원', '$currentMember명 모집'), // 예: 6명 모집
                  Container(width: 1, height: 40, color: Colors.grey[300]), // 중간 구분선
                  _buildInfoColumn('마감일', '11.29'), // 마감일 예시
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 상세 내용 섹션
            const Text(
              '상세 내용',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '매주 화요일 저녁 7시 모임. 구글 폼으로 신청해주세요.\n함께 열심히 공부하실 분 구합니다!',
              style: TextStyle(fontSize: 15, color: Color(0xFF424242), height: 1.6),
            ),
            const SizedBox(height: 40),

            // 문의/질문 섹션
            const Text(
              '문의 / 질문',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Q&A 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.help_outline_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('비전공자도 가능한가요?', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6), size: 20),
                      SizedBox(width: 8),
                      Text('네 가능합니다!', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // 하단 여백
          ],
        ),
      ),

      // 3. 하단 고정 버튼 (공지 내리기 / 마감하기)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('공지 내리기', style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // 사진 속 검은색 버튼? 혹은 파란색
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('마감하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}