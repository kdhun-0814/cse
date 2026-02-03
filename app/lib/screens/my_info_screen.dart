import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../widgets/common/bounceable.dart';
import '../widgets/common/custom_dialog.dart';
import '../widgets/common/custom_loading_indicator.dart';
import '../utils/toast_utils.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      try {
        DocumentSnapshot doc = await _db
            .collection('users')
            .doc(_user!.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
          });
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 비밀번호 변경 다이얼로그 (재인증 포함)
  void _showChangePasswordDialog() {
    final currentPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();

    // Visibility states
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, dialogSetState) {
            return CustomDialog(
              title: "비밀번호 변경",
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "안전을 위해 현재 비밀번호를 확인 후 변경합니다.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7684)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentPwCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: "현재 비밀번호",
                      suffixIcon: Bounceable(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          dialogSetState(() {
                            obscureCurrent = !obscureCurrent;
                          });
                        },
                        child: Container(
                          color: Colors.transparent, // 터치 영역 확보
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: obscureCurrent
                                ? const Color(0xFFB0B8C1)
                                : const Color(0xFF3182F6),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E8EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3182F6)),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPwCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: "새 비밀번호 (8자리 이상)",
                      suffixIcon: Bounceable(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          dialogSetState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: obscureNew
                                ? const Color(0xFFB0B8C1)
                                : const Color(0xFF3182F6),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E8EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3182F6)),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPwCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: "새 비밀번호 확인",
                      suffixIcon: Bounceable(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          dialogSetState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: obscureConfirm
                                ? const Color(0xFFB0B8C1)
                                : const Color(0xFF3182F6),
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E8EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3182F6)),
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
              confirmText: "변경하기",
              cancelText: "취소",
              onCancel: () => Navigator.pop(dialogContext),
              onConfirm: () async {
                final currentPw = currentPwCtrl.text.trim();
                final newPw = newPwCtrl.text.trim();
                final confirmPw = confirmPwCtrl.text.trim();

                if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                  ToastUtils.show(context, "모든 필드를 입력해주세요.", isError: true);
                  return;
                }

                if (newPw.length < 8) {
                  ToastUtils.show(
                    context,
                    "새 비밀번호는 8자리 이상이어야 합니다.",
                    isError: true,
                  );
                  return;
                }

                if (newPw != confirmPw) {
                  ToastUtils.show(context, "새 비밀번호가 일치하지 않습니다.", isError: true);
                  return;
                }

                if (currentPw == newPw) {
                  ToastUtils.show(
                    context,
                    "현재 비밀번호와 다른 비밀번호를 입력해주세요.",
                    isError: true,
                  );
                  return;
                }

                Navigator.pop(dialogContext); // 다이얼로그 닫기

                // 변경 로직 시작
                setState(() => _isLoading = true); // Using parent setState
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || user.email == null) return;

                  // 1. 재인증 (Re-authentication)
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPw,
                  );
                  await user.reauthenticateWithCredential(credential);

                  // 2. 비밀번호 업데이트
                  await user.updatePassword(newPw);

                  if (mounted) {
                    ToastUtils.show(context, "비밀번호가 성공적으로 변경되었습니다.");
                  }
                } on FirebaseAuthException catch (e) {
                  String message = "비밀번호 변경 실패";
                  if (e.code == 'wrong-password' ||
                      e.code == 'invalid-credential') {
                    message = "현재 비밀번호가 일치하지 않습니다.";
                  } else if (e.code == 'weak-password') {
                    message = "비밀번호가 너무 약합니다.";
                  } else if (e.code == 'requires-recent-login') {
                    message = "보안을 위해 다시 로그인 후 시도해주세요.";
                  }
                  if (mounted) ToastUtils.show(context, message, isError: true);
                } catch (e) {
                  if (mounted)
                    ToastUtils.show(context, "오류가 발생했습니다: $e", isError: true);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && _user != null) {
      try {
        if (mounted) setState(() => _isLoading = true);
        File file = File(image.path);
        await FirestoreService().updateProfileImage(_user!.uid, file);
        await _loadUserData(); // 데이터 새로고침
        if (mounted) ToastUtils.show(context, "프로필 사진이 변경되었습니다.");
      } catch (e) {
        if (mounted) ToastUtils.show(context, "사진 변경 실패: $e", isError: true);
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _editName() {
    String lastName = _userData?['last_name'] ?? '';
    String firstName = _userData?['first_name'] ?? '';

    final lastNameController = TextEditingController(text: lastName);
    final firstNameController = TextEditingController(text: firstName);

    showDialog(
      context: context,
      builder: (dialogContext) => CustomDialog(
        title: "이름 수정",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: "성 (Last Name)",
                hintText: "성을 입력하세요",
                filled: true,
                fillColor: const Color(0xFFF2F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: "이름 (First Name)",
                hintText: "이름을 입력하세요",
                filled: true,
                fillColor: const Color(0xFFF2F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        cancelText: "취소",
        confirmText: "저장",
        onCancel: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          if (lastNameController.text.trim().isEmpty ||
              firstNameController.text.trim().isEmpty) {
            ToastUtils.show(dialogContext, "성과 이름을 모두 입력해주세요.", isError: true);
            return;
          }
          try {
            Navigator.pop(dialogContext); // 다이얼로그 닫기 (dialogContext 사용)
            setState(() => _isLoading = true);
            await FirestoreService().updateUserName(
              _user!.uid,
              lastNameController.text.trim(),
              firstNameController.text.trim(),
            );
            await _loadUserData();
            if (mounted)
              ToastUtils.show(context, "이름이 변경되었습니다."); // 화면의 context 사용
          } catch (e) {
            if (mounted)
              ToastUtils.show(
                context,
                "이름 변경 실패: $e",
                isError: true,
              ); // 화면의 context 사용
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F4F6),
        body: Center(child: CustomLoadingIndicator()),
      );
    }

    // 데이터 파싱
    String name = "이름 없음";
    String studentId = "학번 정보 없음";
    String email = _user?.email ?? "이메일 없음";
    String role = "USER";

    if (_userData != null) {
      name =
          "${_userData!['last_name'] ?? ''}${_userData!['first_name'] ?? ''}";
      studentId = "${_userData!['student_id'] ?? '정보 없음'}";
      role = _userData!['role'] ?? 'USER';
    }

    bool isAdmin = role == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text(
          "내 정보",
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF4E5968),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 프로필 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 프로필 이미지 + 수정 버튼
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5E8EB),
                              width: 1,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFF2F4F6),
                            backgroundImage:
                                _userData?['profile_image_url'] != null
                                ? NetworkImage(_userData!['profile_image_url'])
                                : null,
                            child: _userData?['profile_image_url'] == null
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Color(0xFFB0B8C1),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE5E8EB),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Color(0xFF4E5968),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 성명 + 학우님
                  Text(
                    "$name 님",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191F28),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 학번 (도메인 제외)
                  Text(
                    studentId,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 뱃지 표시 (한글 변환)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? const Color(0xFFE8F3FF)
                          : const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAdmin ? "관리자" : "일반 학우",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isAdmin
                            ? const Color(0xFF3182F6)
                            : const Color(0xFF4E5968),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. 상세 정보 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "기본 정보",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191F28),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 성명 + 수정 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "성명",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8B95A1),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333D4B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _editName,
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Color(0xFFB0B8C1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFF2F4F6)),

                  // 학번
                  _buildInfoRow("학번", studentId),
                  const Divider(height: 32, color: Color(0xFFF2F4F6)),

                  // 계정 권한
                  _buildInfoRow("계정 권한", isAdmin ? "관리자" : "일반 학우"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. 계정 설정 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "계정 설정",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191F28),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 비밀번호 변경 버튼
                  Bounceable(
                    onTap: _showChangePasswordDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFF4E5968),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "비밀번호 변경",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333D4B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "현재 비밀번호 확인 후 즉시 변경합니다",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8B95A1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFFB0B8C1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32, color: Color(0xFFF2F4F6)),

                  // 회원 탈퇴 버튼
                  Bounceable(
                    onTap: () async {
                      // 1. 탈퇴 확인 다이얼로그
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => CustomDialog(
                          title: "회원 탈퇴",
                          contentText:
                              "정말로 탈퇴하시겠습니까?\n작성한 공지사항용 데이터 등은\n복구할 수 없습니다.",
                          cancelText: "취소",
                          confirmText: "탈퇴하기",
                          isDestructive: true, // 빨간 버튼
                          onConfirm: () => Navigator.pop(ctx, true),
                          onCancel: () => Navigator.pop(ctx, false),
                        ),
                      );

                      if (confirm == true) {
                        try {
                          setState(() => _isLoading = true);
                          await FirestoreService().deleteUser();

                          // 탈퇴 성공 시 로그인 화면으로 이동
                          if (mounted) {
                            ToastUtils.show(context, "회원 탈퇴가 완료되었습니다.");
                            // 앱 재시작 효과 (모든 라우트 제거하고 웰컴/로그인으로)
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoading = false);
                            // 서비스에서 던진 에러 메시지 그대로 표시 ('보안을 위해...' 등)
                            ToastUtils.show(
                              context,
                              e.toString().replaceAll(
                                "Exception: ",
                                "",
                              ), // 혹시 모를 접두어 제거
                              isError: true,
                            );
                          }
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5F5), // 연한 빨강
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_off_rounded,
                              color: Color(0xFFFF3B30),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              "회원 탈퇴",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFFB0B8C1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B95A1),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333D4B),
          ),
        ),
      ],
    );
  }
}
