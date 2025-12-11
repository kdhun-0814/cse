import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notice.dart';
import '../../screens/notice_detail_screen.dart';

// Assuming FirestoreService and Notice.isUrgent are defined elsewhere
// For the purpose of this edit, I'll assume FirestoreService().getNotices()
// returns a Stream<List<Notice>> and Notice has an isUrgent field.

class UrgentNoticeWidget extends StatelessWidget {
  final bool forceShow; // NEW: 강제 표시 (편집 모드용)

  const UrgentNoticeWidget({super.key, this.forceShow = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('date', descending: true) // 날짜순 정렬
          .limit(100) // 넉넉히 가져와서 필터링 (긴급이 드물 수 있으므로)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error loading notices");
        if (!snapshot.hasData) return const SizedBox.shrink();

        // 1. 긴급 공지 필터링 (is_urgent == true AND 7일 이내)
        final now = DateTime.now();
        final urgentNotices = snapshot.data!.docs
            .map((doc) => Notice.fromFirestore(doc, []))
            .where((n) {
              if (n.isUrgent != true) return false;

              try {
                // 다양한 날짜 형식을 처리하기 위한 로직
                String dateStr = n.date
                    .replaceAll('.', '-')
                    .replaceAll('/', '-')
                    .trim();
                DateTime? noticeDate = DateTime.tryParse(dateStr);

                if (noticeDate == null) {
                  // 형식이 안맞으면 수동 파싱 시도 (YYYY.MM.DD)
                  List<String> parts = n.date.split('.');
                  if (parts.length >= 3) {
                    noticeDate = DateTime(
                      int.parse(parts[0].trim()),
                      int.parse(parts[1].trim()),
                      int.parse(parts[2].trim()),
                    );
                  }
                }

                if (noticeDate != null) {
                  final diff = now.difference(noticeDate).inDays;
                  return diff <= 14; // 7일 -> 14일로 완화 (테스트용 및 실사용성 증대)
                }
              } catch (e) {
                // 파싱 실패 시 안전하게 무시
              }
              return false;
            })
            .toList();

        if (urgentNotices.isEmpty) {
          if (forceShow) {
            return _buildPlaceholder();
          }
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "🚨 긴급 공지",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 전체보기 이동
                    },
                    child: const Text(
                      "전체보기",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // ★ 수정됨: Stack을 이용한 잔상 효과 + PageView
            SizedBox(
              height: 120, // 높이 조정 (가로로 길고 세로는 적당히)
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // 1. 잔상 카드 (데이터가 2개 이상일 때만 표시)
                  if (urgentNotices.length > 1)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      bottom: -10, // 아래로 삐져나옴
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFCDD2).withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  if (urgentNotices.length > 2)
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: -20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFCDD2).withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),

                  // 2. 메인 카드 PageView (세로 스크롤)
                  PageView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: urgentNotices.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 4,
                        ), // 스크롤 시 간격 살짝 (잔상이 보이게)
                        child: _buildUrgentCard(context, urgentNotices[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
            // 3. 인디케이터 등 추가 가능 (선택 사항)
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text("긴급 공지 (표시할 내용 없음)", style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildUrgentCard(BuildContext context, Notice notice) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticeDetailScreen(notice: notice),
          ),
        );
      },
      child: Container(
        width: double.infinity, // 가로 꽉 차게
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE), // 연한 빨강 배경
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFCDD2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 왼쪽: 태그와 날짜
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F), // Strong Red
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "긴급",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notice.date.substring(5), // YYYY.MM.DD -> MM.DD (공간 절약)
                  style: TextStyle(
                    color: const Color(0xFFD32F2F).withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // 오른쪽: 제목
            Expanded(
              child: Text(
                notice.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191F28), // Black/Dark Grey
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // 화살표 아이콘
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD32F2F),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
