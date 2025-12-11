import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String category;
  final String title;
  final String link;
  final String date;
  final String content;
  final List<String> imageUrls;
  final String author;
  final int views;
  final int viewsToday; // NEW
  final List<Map<String, String>> files; // [{'name': '...', 'url': '...'}]
  bool isScraped;
  final bool? isImportant; // NEW
  final bool? isUrgent; // NEW
  final bool isDeleted; // NEW

  Notice({
    required this.id,
    required this.category,
    required this.title,
    this.link = '',
    required this.date,
    required this.content,
    this.imageUrls = const [],
    this.author = "학과사무실",
    this.views = 0,
    this.viewsToday = 0,
    this.files = const [],
    this.isScraped = false,
    this.isImportant = false, // NEW
    this.isUrgent = false, // NEW
    this.isDeleted = false, // NEW
  });

  factory Notice.fromFirestore(DocumentSnapshot doc, List<String> userScraps) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // ★ 날짜 변환 로직
    String formattedDate = '';

    try {
      if (data['date'] is Timestamp) {
        // 1. 타임스탬프인 경우 (default)
        DateTime dt = (data['date'] as Timestamp).toDate();
        formattedDate =
            "${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}";
      } else if (data['date'] is String) {
        // 2. 문자열인 경우 (예외 처리)
        // DB에 "2025.11.20" 혹은 "2025-11-20" 처럼 문자열로 저장된 경우 그대로 사용
        formattedDate = data['date'];
      }
    } catch (e) {
      formattedDate = '날짜 없음';
    }

    // 첨부파일 파싱
    List<Map<String, String>> parsedFiles = [];
    try {
      if (data['files'] != null && data['files'] is List) {
        for (var f in data['files']) {
          if (f is Map) {
            parsedFiles.add({
              'name': f['name']?.toString() ?? '첨부파일',
              'url': f['url']?.toString() ?? '',
            });
          }
        }
      }
    } catch (e) {
      // 파일 파싱 실패 시 무시
    }

    return Notice(
      id: doc.id,
      category: data['category']?.toString() ?? '공지',
      title: data['title']?.toString() ?? '',
      link: data['link']?.toString() ?? '',
      date: formattedDate,
      content: data['content']?.toString() ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? data['images'] ?? []),
      author: data['author']?.toString() ?? '학과사무실',
      views: (data['views'] is int) ? data['views'] : 0,
      viewsToday: (data['views_today'] is int) ? data['views_today'] : 0, // NEW
      files: parsedFiles,
      isScraped: userScraps.contains(doc.id),
      isImportant: data['is_important'] ?? false, // NEW
      isUrgent: data['is_urgent'] ?? false, // NEW
      isDeleted: data['is_deleted'] ?? false, // NEW: Soft delete Support
    );
  }
}
