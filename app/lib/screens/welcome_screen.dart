import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/common/bounceable.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 온보딩 데이터
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "흩어진 학사 공지,\n이제 한곳에서 확인하세요",
      "subtitle": "학교 홈페이지를 일일이 들어갈 필요 없이\n카테고리 별로 공지를 확인할 수 있어요.",
      "image": "assets/images/onboarding_notice.jpg",
    },
    {
      "title": "혼자 공부하기 힘들 땐?\n스터디와 밥 친구 구하기",
      "subtitle": "원하는 목표가 같은 학우들을\n쉽고 빠르게 모을 수 있어요.",
      "image": "assets/images/onboarding_community.jpg",
    },
    {
      "title": "중요한 학사 일정,\n놓치지 말고 미리 챙기세요",
      "subtitle": "수강신청, 국가장학금, 학과행사까지\n중요한 학사일정은 캘린더로 관리해요.",
      "image": "assets/images/onboarding_calender.jpg",
    },
    {
      "title": "복잡한 우리 학과 건물,\n더 이상 헤매지 마세요",
      "subtitle": "강의실 위치가 헷갈릴 땐?\n실제 건물 기반의 3D 지도가 길을 알려드려요.",
      "image": "assets/images/onboarding_map.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final int totalPages = 1 + _onboardingData.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. 슬라이드 영역
          PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildIntroPage();
              }
              final dataIndex = index - 1;
              return _buildPageContent(
                title: _onboardingData[dataIndex]['title']!,
                subtitle: _onboardingData[dataIndex]['subtitle']!,
                imagePath: _onboardingData[dataIndex]['image']!,
              );
            },
          ),

          // 2. 하단 고정 버튼 및 인디케이터
          Positioned(
            left: 24,
            right: 24,
            bottom: 50, // 하단 여백
            child: Column(
              children: [
                // 페이지 인디케이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (index) => _buildDot(index: index),
                  ),
                ),
                const SizedBox(height: 24),

                // 로그인 버튼
                Bounceable(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3182F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "로그인",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 회원가입 버튼
                Bounceable(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "회원가입",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3182F6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ★ 1. 인트로 페이지
  // ★ 수정된 인트로 페이지 (위치 상향 조정)
  Widget _buildIntroPage() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              // mainAxisSize: MainAxisSize.min, // 이 줄 삭제! (전체 높이를 써서 조절하기 위해)
              mainAxisAlignment: MainAxisAlignment.center, // 전체를 중앙 정렬하되...
              children: [
                // 상단 여백을 줄이거나 없애서 전체를 위로 당김
                // const SizedBox(height: 40), // 필요하면 추가

                // 1. 로고 이미지
                SizedBox(
                  height: 350, // 높이는 온보딩과 통일 유지
                  width: double.infinity,
                  child: Center(
                    child: Image.asset(
                      'assets/images/cse_logo.png',
                      width: 300,
                      height: 320,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 2. 앱 이름
                Text(
                  "MY_CSE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3182F6),
                    letterSpacing: 1.2,
                    height: 1.0,
                  ),
                ),

                // ★ 간격 조정: 70 -> 40으로 줄여서 아래 텍스트를 위로 당김
                const SizedBox(height: 40),

                // 3. 소속
                const Text(
                  "경상국립대학교 IT 공과대학\n컴퓨터공학부",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191F28),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // 4. 한 줄 소개
                const Text(
                  "학우들을 위한 스마트한\n학사 통합 플랫폼",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8B95A1),
                    height: 1.5,
                  ),
                ),

                // 하단 여백: 버튼 공간 + α (전체를 위로 밀어 올리는 역할)
                // 이 값을 키우면 전체 내용이 위로 올라갑니다.
                const SizedBox(height: 160),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ★ 온보딩 내용 위젯 (인트로와 배치 통일)
  // ★ 수정된 온보딩 내용 위젯 (투명 위젯으로 높이 자동 맞춤)
  Widget _buildPageContent({
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ★ 1. 이미지 영역 (높이 350으로 강제 고정)
                // 이미지가 아무리 크거나 작아도 이 박스 크기는 350입니다.
                SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      // 이미지가 박스보다 크면 줄이고, 작으면 비율 유지
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 0),

                // ★ 2. MY_CSE 텍스트 (투명 처리)
                // 인트로와 똑같은 공간을 차지하게 해서 밀림 방지
                Text(
                  "MY_CSE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.transparent, // ★ 투명색 (안 보임)
                    letterSpacing: 1.2,
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 0),

                // 3. 텍스트 내용
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191F28),
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8B95A1),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 160), // 하단 버튼 영역 확보
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 점(Dot) 위젯
  Widget _buildDot({required int index}) {
    bool isSelected = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: isSelected ? 24 : 8,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF3182F6) : const Color(0xFFD1D6DB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
