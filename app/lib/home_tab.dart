// lib/home_tab.dart
import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // 배경: 아주 연한 쿨톤 회색
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // 아이폰 스타일 스크롤
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // 1. 상단 메뉴 그리드 (3개씩 2줄, 아이콘 크기 확대됨)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMenuIcon(Icons.campaign_rounded, '긴급', const Color(0xFFEF5350), badgeCount: 2),
                  _buildMenuIcon(Icons.school_rounded, '학사', const Color(0xFF42A5F5), badgeCount: 5),
                  _buildMenuIcon(Icons.emoji_events_rounded, '장학', const Color(0xFFFFCA28)),
                ],
              ),
              const SizedBox(height: 20), // 줄 간격
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMenuIcon(Icons.work_rounded, '취업', const Color(0xFF66BB6A), badgeCount: 12),
                  _buildMenuIcon(Icons.celebration_rounded, '행사', const Color(0xFFAB47BC)),
                  _buildMenuIcon(Icons.storefront_rounded, '광고', const Color(0xFF9E9E9E)),
                ],
              ),

              const SizedBox(height: 40),

              // 2. 섹션 타이틀
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '놓치면 안 되는 중요 공지',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. 공지사항 리스트 (카드 컨테이너)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 예시 데이터: 고정 공지(Pinned) 포함
                    _buildNoticeItem(
                      category: '학사',
                      title: '2025학년도 1학기 수강신청 안내 (필독)',
                      date: '11.20 ~ 11.22',
                      isPinned: true, // 고정 공지 (핀 아이콘)
                      isNew: true,    // 신규 배지
                      showBottomBorder: true,
                    ),
                    _buildNoticeItem(
                      category: '장학',
                      title: '국가장학금 1차 신청 기간',
                      date: 'D-3',
                      isUrgent: true, // 날짜 빨간색
                      showBottomBorder: true,
                    ),
                    _buildNoticeItem(
                      category: '행사',
                      title: '신입생 환영회(OT) 참여 조사',
                      date: '어제',
                      showBottomBorder: true,
                    ),
                    _buildNoticeItem(
                      category: '취업',
                      title: '삼성전자 하반기 공채 상담회',
                      date: '2025.11.20',
                      showBottomBorder: false, // 마지막 줄은 구분선 없음
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 메뉴 아이콘 위젯 (90px 대형 사이즈)
  Widget _buildMenuIcon(IconData icon, String label, Color iconColor, {int badgeCount = 0}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 아이콘 박스 (흰색 배경 + 그림자)
            Container(
              width: 90, 
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32), // 둥근 정도 (Squircle)
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 38),
            ),
            
            // 알림 배지 (빨간색 숫자)
            if (badgeCount > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5252).withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ]
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // 공지사항 리스트 아이템 위젯
  Widget _buildNoticeItem({
    required String category,
    required String title,
    required String date,
    bool isNew = false,
    bool isUrgent = false,
    bool isPinned = false, // 고정 공지 여부
    bool showBottomBorder = true,
  }) {
    // 카테고리별 색상 설정
    Color categoryColor;
    Color categoryBgColor;
    String categoryInitial = category.substring(0, 1);

    switch (category) {
      case '학사':
        categoryColor = const Color(0xFF42A5F5);
        categoryBgColor = const Color(0xFFE3F2FD);
        categoryInitial = '학';
        break;
      case '장학':
        categoryColor = const Color(0xFFFFCA28);
        categoryBgColor = const Color(0xFFFFF8E1);
        categoryInitial = '장';
        break;
      case '취업':
        categoryColor = const Color(0xFF66BB6A);
        categoryBgColor = const Color(0xFFE8F5E9);
        break;
      case '행사':
        categoryColor = const Color(0xFFAB47BC);
        categoryBgColor = const Color(0xFFF3E5F5);
        break;
      default:
        categoryColor = Colors.grey;
        categoryBgColor = Colors.grey.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        // 고정 공지일 경우 배경색을 아주 살짝 다르게 줄 수도 있음 (지금은 투명)
        color: isPinned ? const Color(0xFFFDFEFF) : Colors.transparent,
        border: showBottomBorder
            ? Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))
            : null,
      ),
      child: Row(
        children: [
          // 1. 카테고리 원형 태그
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: categoryBgColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              categoryInitial,
              style: TextStyle(
                color: categoryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // 2. 내용 (제목 + 날짜)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // [핵심] 고정 핀 아이콘 (📌)
                    if (isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Icon(Icons.push_pin_rounded, size: 18, color: Color(0xFF3B82F6)),
                      ),

                    // 제목
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isPinned ? FontWeight.bold : FontWeight.w600, // 고정이면 더 굵게
                          color: const Color(0xFF111111),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // NEW 배지
                    if (isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 6),
                // 날짜
                Text(
                  date,
                  style: TextStyle(
                    color: isUrgent ? const Color(0xFFFF5252) : const Color(0xFF9E9E9E),
                    fontSize: 13,
                    fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // 3. 화살표
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFE0E0E0), size: 22),
        ],
      ),
    );
  }
}