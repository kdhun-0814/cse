import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/toast_utils.dart';
import '../widgets/common/bounceable.dart';
import '../widgets/common/jelly_button.dart';
import 'approval_waiting_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _studentIdCtrl = TextEditingController(); // 학번

  final _emailIdCtrl = TextEditingController(); // 이메일 아이디
  final _emailDomainCtrl = TextEditingController(); // 이메일 도메인 (직접 입력용)
  final _pwCtrl = TextEditingController(); // 비번
  final _lastNameCtrl = TextEditingController(); // 성
  final _firstNameCtrl = TextEditingController(); // 이름
  final _tokenCtrl = TextEditingController(); // 학과 인증 코드

  bool _isLoading = false;
  bool _isObscure = true; // 비밀번호 숨김 여부
  
  // 이메일 도메인 선택
  final List<String> _domainList = [
    'naver.com',
    'gmail.com',
    'daum.net',
    'hanmail.net',
    '직접 입력',
  ];
  String _selectedDomain = 'naver.com'; // 기본값
  bool get _isDirectDomain => _selectedDomain == '직접 입력';

  // 약관 동의 상태
  bool _isServiceTermChecked = false;
  bool _isPrivacyTermChecked = false;

  bool get _isAllChecked => _isServiceTermChecked && _isPrivacyTermChecked;

  void _toggleAll(bool? value) {
    setState(() {
      _isServiceTermChecked = value ?? false;
      _isPrivacyTermChecked = value ?? false;
    });
  }

  Future<void> _signUp() async {
    // 1. 기본 입력 확인
    if (_studentIdCtrl.text.isEmpty ||
        _emailIdCtrl.text.isEmpty ||
        (_isDirectDomain && _emailDomainCtrl.text.isEmpty) ||
        _pwCtrl.text.isEmpty ||
        _lastNameCtrl.text.isEmpty ||
        _firstNameCtrl.text.isEmpty) {
      ToastUtils.show(context, "모든 정보를 입력해주세요.", isError: true);
      return;
    }

    // 2. 학번 자릿수 검사 (10자리)
    int idLength = _studentIdCtrl.text.length;
    if (idLength != 9 && idLength != 10) {
      ToastUtils.show(context, "정확한 학번을 입력해주세요.", isError: true);
      return;
    }

    // 3. 비밀번호 유효성 검사 (영문+숫자 필수, 8자리 이상)
    String password = _pwCtrl.text;
    RegExp passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      ToastUtils.show(context, "비밀번호는 영문+숫자 포함 8자리 이상이어야 합니다.", isError: true);
      return;
    }

    // 4. 학과 인증 코드 검증
    String token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      ToastUtils.show(context, "학과 인증 코드를 입력해주세요.", isError: true);
      return;
    }

    // 5. 약관 동의 확인
    if (!_isAllChecked) {
      ToastUtils.show(context, "필수 약관에 모두 동의해주세요.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 인증 코드 확인
      bool isValidToken = await FirestoreService().verifySignupToken(token);
      if (!isValidToken) {
        if (mounted) {
          ToastUtils.show(context, "학과 인증 코드가 올바르지 않습니다.", isError: true);
          setState(() => _isLoading = false);
        }
        return;
      }

      // 학번 중복 확인
      if (await FirestoreService().isStudentIdTaken(_studentIdCtrl.text.trim())) {
        if (mounted) {
          ToastUtils.show(context, "이미 가입된 학번입니다.", isError: true);
          setState(() => _isLoading = false);
        }
        return;
      }

      // 이메일 조합
      String emailId = _emailIdCtrl.text.trim();
      String emailDomain = _isDirectDomain 
          ? _emailDomainCtrl.text.trim() 
          : _selectedDomain;
      String email = "$emailId@$emailDomain";

      // 이름 합치기
      String lastName = _lastNameCtrl.text.trim();
      String firstName = _firstNameCtrl.text.trim();
      String fullName = "$lastName$firstName";

      // 4. Firebase Auth 계정 생성
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _pwCtrl.text.trim(),
          );

      // (이메일 인증 제거)
      // await userCred.user!.sendEmailVerification();

      // 5. Firestore DB 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
            'student_id': _studentIdCtrl.text.trim(),
            'email': email,
            'name': fullName, // 전체 이름
            'last_name': lastName, // 성
            'first_name': firstName, // 이름
            'role': 'USER',
            'status': 'pending', // 바로 Pending 상태
            'created_at': FieldValue.serverTimestamp(),
            'approved_at': null,
            'expires_at': null,
            'push_settings': {}, // 초기값
            'home_widget_config': [], // 초기값
          });

      if (mounted) {
        ToastUtils.show(context, "회원가입 신청이 완료되었어요.");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ApprovalWaitingScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      String message = "가입 실패: $e";
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        message = "이미 가입된 학번(아이디)입니다.";
      }
      ToastUtils.show(context, message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ★ 통일된 디자인의 AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "회원가입",
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
            fontSize: 22,
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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "실제 학번과 실명을 입력해주세요.\n관리자 승인 후 정상적인 앱 이용이 가능해요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8B95A1),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 1. 학번 입력
              const Text(
                "학번",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _studentIdCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  hintText: "예: 20xxxxxxxx",
                  hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ), // 둥근 테두리
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF3182F6)),
                  ),
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: Color(0xFF3182F6),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. 이메일 입력
              const Text(
                "이메일",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 이메일 아이디
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _emailIdCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "이메일",
                        hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFF3182F6)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "@",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B95A1),
                      ),
                    ),
                  ),
                  // 도메인 선택/입력
                  Expanded(
                    flex: 1,
                    child: _isDirectDomain
                        ? TextField(
                            controller: _emailDomainCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "직접 입력",
                              hintStyle: const TextStyle(color: Color(0xFFC5C8CE)),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Color(0xFF3182F6)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close_rounded, color: Color(0xFFB0B8C1), size: 18),
                                onPressed: () {
                                  setState(() {
                                    _selectedDomain = _domainList[0]; // 목록으로 복귀
                                  });
                                },
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E8EB)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                scrollbarTheme: ScrollbarThemeData(
                                  thumbColor: WidgetStateProperty.all(const Color(0xFFE5E8EB)),
                                  trackColor: WidgetStateProperty.all(Colors.transparent),
                                  // trackBorderColor: WidgetStateProperty.all(Colors.transparent),
                                  radius: const Radius.circular(4),
                                  thickness: WidgetStateProperty.all(6.0),
                                  thumbVisibility: WidgetStateProperty.all(true), // 항상 표시 (데스크탑/웹 고려)
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedDomain,
                                  isExpanded: true,
                                  dropdownColor: Colors.white, // 배경 흰색 명시
                                  borderRadius: BorderRadius.circular(12), // 메뉴 둥근 모서리
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF8B95A1)),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF333D4B),
                                  ),
                                  items: _domainList.map((domain) {
                                    return DropdownMenuItem(
                                      value: domain,
                                      child: Text(domain),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedDomain = value;
                                        if (_isDirectDomain) {
                                          _emailDomainCtrl.clear();
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "비밀번호 분실 시 재설정 링크가 전송되니 실제 사용 중인 이메일을 입력해주세요.",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B95A1),
                ),
              ),
              const SizedBox(height: 24),

              // 2. 이름 입력 (Row)
              const Text(
                "이름 (실명)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(
                        hintText: "성",
                        hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFF3182F6)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(
                        hintText: "이름",
                        hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFF3182F6)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. 비밀번호 입력
              const Text(
                "비밀번호",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pwCtrl,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  hintText: "영문+숫자 포함 8자리 이상",
                  hintStyle: const TextStyle(color: Color(0xFFC5C8CE)),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF3182F6)),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF3182F6),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: JellyButton(
                      isActive: !_isObscure,
                      activeIcon: Icons.visibility_outlined,
                      inactiveIcon: Icons.visibility_off_outlined,
                      activeColor: const Color(0xFF3182F6),
                      inactiveColor: const Color(0xFFB0B8C1),
                      size: 24,
                      onTap: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. 학과 인증 코드
              const Text(
                "학과 인증 코드",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "학생회에서 별도로 안내 받은 인증코드를 입력해주세요.",
                style: TextStyle(fontSize: 12, color: Color(0xFF8B95A1)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(
                  hintText: "인증 코드 입력",
                  hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF3182F6)),
                  ),
                  prefixIcon: Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF3182F6),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 약관 동의 섹션
              _buildTermSection(),

              const SizedBox(height: 40),

              // 4. 가입 버튼
              // 4. 가입 버튼
              SizedBox(
                width: double.infinity,
                child: Bounceable(
                  onTap: _isLoading ? null : _signUp,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3182F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "가입 신청하기",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전체 동의
        // 전체 동의
        Bounceable(
          onTap: () => _toggleAll(!_isAllChecked),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.transparent, // 터치 영역 확보
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isAllChecked,
                    activeColor: const Color(0xFF3182F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: _toggleAll,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "약관 전체 동의",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333D4B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFFF2F4F6)),
        const SizedBox(height: 8),

        // 서비스 이용약관
        _buildTermItem(
          "서비스 이용약관 동의 (필수)",
          _isServiceTermChecked,
          (val) => setState(() => _isServiceTermChecked = val ?? false),
          _showServiceTerms,
        ),

        // 개인정보 수집 이용
        _buildTermItem(
          "개인정보 수집 및 이용 동의 (필수)",
          _isPrivacyTermChecked,
          (val) => setState(() => _isPrivacyTermChecked = val ?? false),
          _showPrivacyTerms,
        ),
      ],
    );
  }

  Widget _buildTermItem(
    String title,
    bool isChecked,
    ValueChanged<bool?> onChanged,
    VoidCallback onDetail,
  ) {
    return Bounceable(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.transparent, // 터치 영역 확보
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                activeColor: const Color(0xFF3182F6),
                side: const BorderSide(color: Color(0xFFD1D6DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4E5968)),
              ),
            ),
            Bounceable(
              onTap: onDetail,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB0B8C1),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
    );
  }

  void _showPrivacyTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }
}
