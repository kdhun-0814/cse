import 'package:flutter/material.dart';
import '../../screens/notice_list_screen.dart';
import '../../services/firestore_service.dart';

class CategoryGridWidget extends StatefulWidget {
  final FirestoreService firestoreService;

  const CategoryGridWidget({super.key, required this.firestoreService});

  @override
  State<CategoryGridWidget> createState() => _CategoryGridWidgetState();
}

class _CategoryGridWidgetState extends State<CategoryGridWidget> {
  // 스트림 캐싱: 빌드할 때마다 스트림이 재생성되지 않도록 initState에서 초기화
  late Map<String, Stream<int>> _streamCache;

  @override
  void initState() {
    super.initState();
    _streamCache = {
      "학사": widget.firestoreService.getNoticeCount("학사"),
      "장학": widget.firestoreService.getNoticeCount("장학"),
      "취업": widget.firestoreService.getNoticeCount("취업"),
      "학과행사": widget.firestoreService.getNoticeCount("학과행사"),
      "외부행사": widget.firestoreService.getNoticeCount("외부행사"),
      "공모전": widget.firestoreService.getNoticeCount("공모전"),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _menuItem(
                context,
                Icons.school_rounded,
                "학사",
                const Color(0xFFFFEBEE),
                const Color(0xFFEF5350), // Lighter Red
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _menuItem(
                context,
                Icons.emoji_events_rounded,
                "장학",
                const Color(0xFFFFF3E0),
                const Color(0xFFFFB74D), // Lighter Orange
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _menuItem(
                context,
                Icons.work_rounded,
                "취업",
                const Color(0xFFE8F5E9),
                const Color(0xFF81C784), // Lighter Green
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _menuItem(
                context,
                Icons.celebration_rounded,
                "학과행사",
                const Color(0xFFF3E5F5),
                const Color(0xFFBA68C8), // Lighter Purple
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _menuItem(
                context,
                Icons.public_rounded,
                "외부행사",
                const Color(0xFFE0F7FA),
                const Color(0xFF4DD0E1), // Lighter Cyan
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _menuItem(
                context,
                Icons.lightbulb_rounded,
                "공모전",
                const Color(0xFFFFFDE7),
                const Color(0xFFFFD54F), // Lighter Yellow
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
  ) {
    // 캐시된 스트림 사용
    final stream = _streamCache[label];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NoticeListScreen(title: label, themeColor: iconColor),
          ),
        );
      },
      child: Container(
        height: 140, // 높이 증가
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E8EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70, // 크기 증가
                  height: 70, // 크기 증가
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 36), // 아이콘 크기 증가
                ),
                if (stream != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: StreamBuilder<int>(
                      stream: stream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == 0) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              snapshot.data! > 99
                                  ? '99+'
                                  : snapshot.data.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16.5, // 텍스트 크기 증가
                fontWeight: FontWeight.bold,
                color: Color(0xFF333D4B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
