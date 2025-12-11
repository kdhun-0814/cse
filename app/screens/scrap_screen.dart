import 'package:flutter/material.dart';
import '../models/notice.dart';
import 'notice_detail_screen.dart';

class ScrapScreen extends StatefulWidget {
  const ScrapScreen({super.key});

  @override
  State<ScrapScreen> createState() => _ScrapScreenState();
}

class _ScrapScreenState extends State<ScrapScreen> {
  // 현재 선택된 카테고리 (기본값: 전체)
  String _selectedCategory = "전체";

  // 분류 목록
  final List<String> _categories = ["전체", "긴급", "학사", "장학", "취업", "행사", "광고"];

  // 색상 헬퍼 (홈 화면과 통일)
  Color _getCategoryColor(String category) {
    switch (category) {
      case "긴급": return const Color(0xFFFF8A80);
      case "학사": return const Color(0xFF82B1FF);
      case "장학": return const Color(0xFFFFD180);
      case "취업": return const Color(0xFFA5D6A7);
      case "행사": return const Color(0xFFCE93D8);
      case "광고": return const Color(0xFFB0BEC5);
      default: return const Color(0xFF3182F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 스크랩된 공지 가져오기
    List<Notice> scrapedNotices = dummyNotices.where((n) => n.isScraped).toList();

    // 2. 카테고리 필터링
    if (_selectedCategory != "전체") {
      scrapedNotices = scrapedNotices.where((n) => n.category == _selectedCategory).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text('나의 스크랩', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF191F28))),
        elevation: 0,
        backgroundColor: const Color(0xFFF2F4F6),
      ),
      body: Column(
        children: [
          // ★ 상단 필터바
          Container(
            color: const Color(0xFFF2F4F6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF3182F6), // 선택 시 파란색
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF4E5968),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E8EB)),
                      ),
                      showCheckmark: false, // 체크표시 제거 (깔끔하게)
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ★ 리스트
          Expanded(
            child: scrapedNotices.isEmpty
                ? _buildEmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: scrapedNotices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildScrapItem(scrapedNotices[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bookmark_outline_rounded, size: 60, color: Color(0xFFD1D6DB)),
          SizedBox(height: 16),
          Text("해당하는 스크랩 공지가 없어요", style: TextStyle(fontSize: 16, color: Color(0xFF8B95A1))),
        ],
      ),
    );
  }

  Widget _buildScrapItem(Notice notice) {
    final color = _getCategoryColor(notice.category);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoticeDetailScreen(notice: notice)),
        ).then((_) {
          setState(() {});
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 카테고리 뱃지 (색상 적용)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(notice.category, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(notice.date, style: const TextStyle(fontSize: 13, color: Color(0xFF8B95A1))),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      notice.isScraped = !notice.isScraped;
                    });
                  },
                  child: const Icon(Icons.bookmark_rounded, size: 24, color: Color(0xFFFFD180)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notice.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF191F28)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}