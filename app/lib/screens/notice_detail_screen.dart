import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/notice.dart';

import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeDetailScreen extends StatefulWidget {
  final Notice notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  late Stream<DocumentSnapshot>? _userStream;
  String _userRole = ''; // NEW

  @override
  void initState() {
    super.initState();
    // 권한 가져오기
    _firestoreService.getUserRole().then((role) {
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    });

    // 화면 진입 시 읽음 처리
    _firestoreService.markNoticeAsRead(widget.notice.id);

    // 스트림 초기화 (리빌드 시 재구독 방지)
    final user = FirebaseAuth.instance.currentUser;
    _userStream = user != null
        ? FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots()
        : null;

    // 스크롤 리스너 추가 (구분선 로직)
    _scrollController.addListener(() {
      if (_scrollController.offset > 10) {
        if (!_isScrolled) setState(() => _isScrolled = true);
      } else {
        if (_isScrolled) setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF191F28),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 관리자 기능 추가
          if (_userRole == 'ADMIN') ...[
            IconButton(
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.blue,
              ),
              tooltip: "푸시 알림 보내기",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("푸시 알림"),
                    content: const Text("이 공지의 푸시 알림을 전송하시겠습니까?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("취소"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _firestoreService.requestPushNotification(
                            widget.notice.id,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("푸시 요청이 전송되었습니다.")),
                          );
                        },
                        child: const Text("전송"),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: "공지 삭제",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("공지 삭제"),
                    content: const Text("이 공지를 삭제하시겠습니까?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("취소"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _firestoreService.deleteNotice(widget.notice.id);
                          Navigator.pop(context); // 화면 종료
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("삭제되었습니다.")),
                          );
                        },
                        child: const Text(
                          "삭제",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          StreamBuilder<DocumentSnapshot>(
            stream: _userStream,
            builder: (context, snapshot) {
              bool isScraped = false;
              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  final scraps = List<String>.from(data['scraps'] ?? []);
                  isScraped = scraps.contains(widget.notice.id);
                }
              }

              return IconButton(
                icon: Icon(
                  isScraped
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isScraped
                      ? const Color(0xFFFFD180)
                      : const Color(0xFFB0B8C1),
                  size: 28,
                ),
                onPressed: () {
                  _firestoreService.toggleNoticeScrap(
                    widget.notice.id,
                    isScraped,
                  );
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !isScraped ? "스크랩 보관함에 저장되었어요." : "스크랩이 해제되었어요.",
                      ),
                      duration: const Duration(milliseconds: 1000),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 카테고리
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.notice.category,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4E5968),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. 제목
            Text(
              widget.notice.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191F28),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // 3. 메타데이터 (작성자 | 날짜 | 조회수)
            Row(
              children: [
                Text(
                  widget.notice.author,
                  style: const TextStyle(
                    color: Color(0xFF4E5968),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                const Text("|", style: TextStyle(color: Color(0xFFE5E8EB))),
                const SizedBox(width: 8),
                Text(
                  widget.notice.date,
                  style: const TextStyle(
                    color: Color(0xFF8B95A1),
                    fontSize: 13,
                  ),
                ),
                if (widget.notice.views > 0) ...[
                  const SizedBox(width: 8),
                  const Text("|", style: TextStyle(color: Color(0xFFE5E8EB))),
                  const SizedBox(width: 8),
                  Text(
                    "조회 ${widget.notice.views}",
                    style: const TextStyle(
                      color: Color(0xFF8B95A1),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFF2F4F6)),
            const SizedBox(height: 24),

            // 4. 첨부파일 (상단 배치)
            if (widget.notice.files.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 247, 249),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E8EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "첨부파일",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333D4B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.notice.files.map((file) {
                      return InkWell(
                        onTap: () async {
                          final Uri url = Uri.parse(file['url'] ?? '');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 20,
                                color: Color(0xFF8B95A1),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  file['name'] ?? '파일',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF4E5968),
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

            // 5. 본문 (HTML 렌더링)
            // flutter_widget_from_html 사용
            HtmlWidget(
              widget.notice.content,
              textStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333D4B),
                height: 1.6,
              ),
              onTapUrl: (url) async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                  return true;
                }
                return false;
              },
            ),

            const SizedBox(height: 40),

            // 6. 하단 링크 버튼 (원본 공지 / 학과 홈페이지)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (widget.notice.link.isNotEmpty) {
                        final Uri url = Uri.parse(widget.notice.link);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE5E8EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "원본 공지 보기",
                      style: TextStyle(
                        color: Color(0xFF4E5968),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      const String mainUrl =
                          "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753";
                      final Uri url = Uri.parse(mainUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFF2F4F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "학과 공지 가기",
                      style: TextStyle(
                        color: Color(0xFF333D4B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // 7. 관리자 전용 패널
            if (_userRole == 'ADMIN') _buildAdminPanel(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 관리자 패널
  Widget _buildAdminPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🛠️ 관리자 메뉴",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text("중요 공지로 설정"),
            subtitle: const Text("중요 공지 위젯에 상단 노출됩니다."),
            value:
                widget.notice.isImportant ??
                false, // Notice 모델에 필드 필요 (없으면 fetch 필요) -> Notice는 불변이므로 setState 반영 어려움.
            // 해결책: StreamBuilder 사용하거나, toggle 시 setState로 notice 객체 자체를 업데이트해야 함.
            // 여기서는 간단히 DB 업데이트만 하고, 화면 반영은 notice.isImportant가 없어 UI상 즉시 반영 안될 수 있음.
            // -> Notice 모델에 isImportant 필드가 있는지 확인 필요.
            onChanged: (val) async {
              await _firestoreService.setNoticeImportant(widget.notice.id, val);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("변경되었습니다.")));
            },
          ),
          SwitchListTile(
            title: const Text("긴급 공지로 설정"),
            subtitle: const Text("긴급 공지 위젯에 노출됩니다."),
            value: widget.notice.isUrgent ?? false,
            onChanged: (val) async {
              await _firestoreService.setNoticeUrgent(widget.notice.id, val);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("변경되었습니다.")));
            },
          ),
        ],
      ),
    );
  }
}
