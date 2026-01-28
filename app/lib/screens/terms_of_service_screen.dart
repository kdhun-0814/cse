import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "서비스 이용약관",
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF191F28),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              "제1조 (목적)",
              "본 약관은 MY_CSE(이하 \"앱\")가 제공하는 공지사항 분류, 행사 참여 관리, 실내 내비게이션 등 학과 특화 서비스의 이용 조건 및 절차에 관한 사항을 규정함을 목적으로 합니다.",
            ),
            const SizedBox(height: 24),
            _buildSection(
              "제2조 (용어의 정의)",
              """• "이용자"란 학과 소속 학생으로서 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.

• "학생회 관리자"란 공지 등록 및 행사 참여 명단을 관리하는 권한을 가진 자를 말합니다.

• "AI 분류 서비스"란 파이썬 기반 알고리즘을 통해 공지사항을 카테고리별로 자동 분류하는 기능을 말합니다.""",
            ),
            const SizedBox(height: 24),
            _buildSection(
              "제3조 (회원가입 및 학적 정보 확인)",
              """본 앱은 학과 전용 서비스로, 이용자는 가입 시 성명과 학번을 정확히 입력해야 합니다.

입력된 정보는 학생회 측의 학적 명부와 대조하여 본인 확인 및 서비스 이용 승인 용도로 사용됩니다. 허위 정보를 입력할 경우 서비스 이용이 제한될 수 있습니다.""",
            ),
            const SizedBox(height: 24),
            _buildSection("제4조 (서비스의 내용)", """앱은 이용자에게 다음과 같은 기능을 제공합니다.

• AI 공지 분류: 학사, 장학, 행사, 긴급 등 카테고리별 공지 자동 분류 및 조회

• 행사 관리: MT, 새내기 배움터 등 학생회 주관 행사 참여 신청 및 확인

• 캘린더 연동: 수강신청, 장학금 신청 등 주요 학사 일정의 자동 캘린더 등록

• 커뮤니티: 학과 내 스터디 그룹 및 소모임 개설 및 참여

• 실내 내비게이션: 학과 건물 내 주요 시설 길 안내"""),
            const SizedBox(height: 24),
            _buildSection(
              "제5조 (AI 서비스 이용 및 책임의 한계)",
              """• 분류 정확성: AI를 통한 공지 자동 분류는 이용자의 편의를 위한 보조적 기능입니다. 기술적 한계로 인해 오분류가 발생할 수 있습니다.

• 최종 확인 의무: 수강신청, 장학금 신청 등 중요한 학사 일정의 경우, 이용자는 반드시 학교 공식 홈페이지를 통해 최종 확인해야 하며, AI 분류 오류로 인해 발생하는 불이익에 대해 본 앱은 책임을 지지 않습니다.""",
            ),
            const SizedBox(height: 24),
            _buildSection(
              "제6조 (실내 내비게이션 이용)",
              """실내 내비게이션은 건물의 구조적 특성 및 기기 환경에 따라 실제 위치와 오차가 발생할 수 있습니다.

원활한 서비스 제공을 위해 이용자의 기기 위치 정보 접근 권한이 필요할 수 있습니다.""",
            ),
            const SizedBox(height: 24),
            _buildSection(
              "제7조 (이용자의 의무)",
              """이용자는 타인의 정보를 도용하거나 서비스를 부정하게 사용하여서는 안 됩니다.

커뮤니티(스터디, 소모임) 이용 시 타인에게 불쾌감을 주는 행위나 영리 목적의 광고 행위를 금지합니다.""",
            ),
            const SizedBox(height: 24),
            _buildSection(
              "제8조 (약관의 개정)",
              "본 약관은 학생회 운영 위원회의 결정에 따라 개정될 수 있으며, 개정 시 앱 내 공지사항을 통해 고지합니다.",
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191F28),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4E5968),
            height: 1.6,
          ),
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}
