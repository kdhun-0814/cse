import 'package:flutter/material.dart';
import '../../screens/notice_list_screen.dart';
import '../../services/firestore_service.dart';
import '../common/bounceable.dart'; // Toss-style Interaction

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
                Colors.grey[100]!, // Background Grey
                Colors.blue[700]!, // Icon Strong Blue
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _menuItem(
                context,
                Icons.emoji_events_rounded,
                "장학",
                Colors.grey[100]!,
                Colors.orange[700]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _menuItem(
                context,
                Icons.work_rounded,
                "취업",
                Colors.grey[100]!,
                Colors.green[700]!,
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
                Icons.lightbulb_rounded,
                "공모전",
                Colors.grey[100]!,
                Colors.amber[700]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _menuItem(
                context,
                Icons.celebration_rounded,
                "학과행사",
                Colors.grey[100]!,
                Colors.purple[700]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _menuItem(
                context,
                Icons.public_rounded,
                "외부행사",
                Colors.grey[100]!,
                Colors.grey[700]!,
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

    return Bounceable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NoticeListScreen(title: label, themeColor: iconColor),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 140, // 높이 증가
        decoration: BoxDecoration(
          color: Colors.white, // 배경은 항상 흰색
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
                    color: bgColor, // 아이콘 주변 원에 파스텔 색상 적용
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
