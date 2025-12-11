import 'package:flutter/material.dart';
import '../models/notice.dart'; // 모델 import
import 'notice_detail_screen.dart'; // 상세화면 import

class NoticeListScreen extends StatefulWidget {
  final String title;
  final Color themeColor;

  const NoticeListScreen({super.key, required this.title, required this.themeColor});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  @override
  Widget build(BuildContext context) {
    // 선택된 카테고리에 맞는 데이터만 필터링 (예: '학사'를 누르면 학사 공지만)
    // '긴급공지' 같은 메뉴명을 실제 데이터의 category와 매칭시키는 로직은 
    // 나중에 정확히 맞춰야 하지만, 지금은 일단 '전체' 혹은 '유사한 것'을 보여주도록 구현합니다.
    List<Notice> filteredNotices = dummyNotices.where((n) {
      if (widget.title == '전체') return true;
      return n.category == widget.title || widget.title.contains(n.category); 
    }).toList();
    
    // 데이터가 없으면 전체 보여주기 (테스트용)
    if (filteredNotices.isEmpty) filteredNotices = dummyNotices;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F6),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF191F28)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: const TextStyle(color: Color(0xFF191F28), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: filteredNotices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildListItem(filteredNotices[index]);
        },
      ),
    );
  }

  Widget _buildListItem(Notice notice) {
    return GestureDetector(
      onTap: () {
        // 상세 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoticeDetailScreen(notice: notice)),
        ).then((_) {
          // 상세화면에서 스크랩 상태를 바꾸고 돌아왔을 때 리스트도 갱신하기 위해
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
                Text(
                  notice.date,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8B95A1)),
                ),
                const Spacer(),
                // 리스트에서도 바로 스크랩 가능하도록
                GestureDetector(
                  onTap: () {
                    setState(() {
                      notice.isScraped = !notice.isScraped;
                    });
                  },
                  child: Icon(
                    notice.isScraped ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 24,
                    color: notice.isScraped ? const Color(0xFFFFD180) : const Color(0xFFD1D6DB), // 노란색 vs 회색
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notice.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF191F28)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                notice.category,
                style: TextStyle(fontSize: 12, color: widget.themeColor, fontWeight: FontWeight.w600),
              ),
            )
          ],
        ),
      ),
    );
  }
}