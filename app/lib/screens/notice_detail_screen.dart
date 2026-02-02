import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/notice.dart';

import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/toast_utils.dart';
import '../widgets/common/jelly_button.dart';
import '../widgets/common/custom_dialog.dart';
import '../widgets/common/bounceable.dart';

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
  late bool _isImportant;
  late bool _isUrgent;

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

    _isImportant = widget.notice.isImportant ?? false;
    _isUrgent = widget.notice.isUrgent ?? false;

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
                  builder: (context) => CustomDialog(
                    title: "푸시 알림",
                    contentText: "이 공지의 푸시 알림을 전송하시겠습니까?",
                    cancelText: "취소",
                    confirmText: "전송",
                    onCancel: () => Navigator.pop(context),
                    onConfirm: () {
                      Navigator.pop(context);
                      _firestoreService.requestPushNotification(
                        widget.notice.id,
                      );
                      ToastUtils.show(context, "푸시 알림이 전송되었습니다.");
                    },
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
                  builder: (context) => CustomDialog(
                    title: "공지 삭제",
                    contentText: "이 공지를 삭제하시겠습니까?",
                    cancelText: "취소",
                    confirmText: "삭제",
                    isDestructive: true,
                    onConfirm: () {
                      Navigator.pop(context);
                      _firestoreService.deleteNotice(widget.notice.id);
                      Navigator.pop(context); // 화면 종료
                      ToastUtils.show(context, "공지가 삭제되었습니다.");
                    },
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

              return JellyButton(
                isActive: isScraped,
                activeIcon: Icons.bookmark_rounded,
                inactiveIcon: Icons.bookmark_border_rounded,
                activeColor: const Color(0xFFFFD180),
                inactiveColor: const Color(0xFFB0B8C1),
                size: 28,
                onTap: () {
                  _firestoreService.toggleNoticeScrap(
                    widget.notice.id,
                    isScraped,
                  );
                  ToastUtils.show(
                    context,
                    !isScraped ? "스크랩 보관함에 저장되었어요." : "스크랩이 해제되었어요.",
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
                      return Bounceable(
                        onTap: () async {
                          final Uri url = Uri.parse(file['url'] ?? '');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
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
                    }),
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
                try {
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return true;
                  }
                  // Fallback: try launch without checking
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    return true;
                  }
                } catch (e) {
                  debugPrint("Error launching URL: $e");
                }
                return false;
              },
            ),

            const SizedBox(height: 40),

            // 6. 하단 링크 버튼 (원본 공지 / 학과 홈페이지)
            Row(
              children: [
                Expanded(
                  child: Bounceable(
                    onTap: () async {
                      try {
                        if (widget.notice.link.isNotEmpty) {
                          Uri url = Uri.parse(widget.notice.link);
                          if (!url.hasScheme) {
                            url = Uri.parse("https://${widget.notice.link}");
                          }
                          // launchUrl returns bool, but on some versions checking only canLaunchUrl is enough
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            // Try one more time without mode
                            await launchUrl(url);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ToastUtils.show(
                            context,
                            "링크를 열 수 없습니다: $e",
                            isError: true,
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E8EB)),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Bounceable(
                    onTap: () async {
                      const String mainUrl =
                          "https://www.gnu.ac.kr/cse/na/ntt/selectNttList.do?mi=17093&bbsId=4753";
                      try {
                        final Uri url = Uri.parse(mainUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          await launchUrl(url);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ToastUtils.show(
                            context,
                            "학과 페이지를 열 수 없습니다.",
                            isError: true,
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF2F4F6),
                      ),
                      alignment: Alignment.center,
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
            "관리자 메뉴",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text(
              "중요 공지로 설정",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333D4B),
              ),
            ),
            subtitle: const Text("중요 공지 위젯에 상단 노출됩니다."),
            value: _isImportant,
            activeThumbColor: const Color(0xFF3182F6),
            onChanged: (val) async {
              setState(() {
                _isImportant = val;
              });
              await _firestoreService.setNoticeImportant(widget.notice.id, val);
              if (mounted) {
                ToastUtils.show(context, "변경되었습니다.");
              }
            },
          ),
          SwitchListTile(
            title: const Text(
              "긴급 공지로 설정",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333D4B),
              ),
            ),
            subtitle: const Text("긴급 공지 위젯에 노출됩니다."),
            value: _isUrgent,
            activeThumbColor: const Color(0xFF3182F6),
            onChanged: (val) async {
              setState(() {
                _isUrgent = val;
              });
              await _firestoreService.setNoticeUrgent(widget.notice.id, val);
              if (mounted) {
                ToastUtils.show(context, "변경되었습니다.");
              }
            },
          ),
        ],
      ),
    );
  }
}
