import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "개인정보 수집 및 이용 동의",
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
            const Text(
              "MY_CSE(이하 '앱')는 학과 서비스 제공을 위해 아래와 같이 귀하의 개인정보를 수집·이용하고자 합니다. 내용을 자세히 읽으신 후 동의 여부를 결정해 주시기 바랍니다.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4E5968),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "1. 개인정보 수집 및 이용 내역",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191F28),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoTable(),
            const SizedBox(height: 32),
            const Text(
              "2. 동의 거부 권리 및 불이익 안내",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191F28),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "귀하는 위와 같은 개인정보 수집 및 이용에 동의하지 않을 권리가 있습니다.\n\n단, 필수 항목에 대한 동의를 거부하실 경우 학적 확인이 불가능하여 학생회 전용 서비스(공지 확인, 행사 신청 등) 이용이 제한될 수 있습니다.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4E5968),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E8EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          _buildTableRow(
            "성명, 학번, 학과",
            "[필수] 서비스 이용에 따른 본인 식별, 학적 확인, 학생회 주관 행사(MT, 새내기 배움터 등) 참여 명단 작성",
            "앱 탈퇴 시까지",
            isRequired: true,
          ),
          _buildTableRow(
            "휴대폰 번호",
            "[선택] 긴급 공지사항 푸시 알림 발송, 행사 관련 긴급 연락 및 안내",
            "앱 탈퇴 시까지",
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "수집 항목",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191F28),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "수집 및 이용 목적",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191F28),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "보유 및 이용 기간",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191F28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String items,
    String purpose,
    String period, {
    required bool isRequired,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E8EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              items,
              style: TextStyle(
                fontSize: 13,
                color: isRequired
                    ? const Color(0xFF191F28)
                    : const Color(0xFF6B7684),
                height: 1.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              purpose,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4E5968),
                height: 1.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              period,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4E5968),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
