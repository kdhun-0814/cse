import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/common/custom_loading_indicator.dart';
import '../widgets/common/custom_dialog.dart';
import '../utils/toast_utils.dart';
import '../widgets/common/bounceable.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _studentIdCtrl = TextEditingController(); // 학번
  final _pwCtrl = TextEditingController(); // 비번
  final _lastNameCtrl = TextEditingController(); // 성
  final _firstNameCtrl = TextEditingController(); // 이름
  
  File? _imageFile; // 재학증명서 이미지
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, 
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ToastUtils.show(context, "이미지를 불러오는데 실패했습니다.", isError: true);
    }
  }

  Future<void> _signUp() async {
    // 1. 기본 입력 확인
    if (_studentIdCtrl.text.isEmpty ||
        _pwCtrl.text.isEmpty ||
        _lastNameCtrl.text.isEmpty ||
        _firstNameCtrl.text.isEmpty) {
      ToastUtils.show(context, "모든 정보를 입력해주세요.", isError: true);
      return;
    }

    // 2. 학번 자릿수 검사 (9~10자리)
    int idLength = _studentIdCtrl.text.length;
    if (idLength < 9 || idLength > 10) {
      ToastUtils.show(context, "학번은 9자리 또는 10자리여야 합니다.", isError: true);
      return;
    }

    // 3. 비밀번호 유효성 검사 (영문+숫자 필수, 8자리 이상)
    String password = _pwCtrl.text;
    RegExp passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      ToastUtils.show(context, "비밀번호는 영문+숫자 포함 8자리 이상이어야 합니다.", isError: true);
      return;
    }

    // 4. 재학증명서 이미지 확인
    if (_imageFile == null) {
      ToastUtils.show(context, "재학증명서(캡처) 이미지를 첨부해주세요.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 학교 도메인 자동 완성
      String email = "${_studentIdCtrl.text.trim()}@gnu.ac.kr";

      // 이름 합치기
      String lastName = _lastNameCtrl.text.trim();
      String firstName = _firstNameCtrl.text.trim();
      String fullName = "$lastName$firstName";

      // 5. Firebase Auth 계정 생성
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _pwCtrl.text.trim(),
          );

      // 6. 재학증명서 이미지 업로드
      String uid = userCred.user!.uid;
      String fileName = "enrollment_proof_$uid.jpg";
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("enrollment_proofs")
          .child(fileName);
      
      await storageRef.putFile(_imageFile!);
      String proofUrl = await storageRef.getDownloadURL();

      // 7. Firestore DB 저장 (Pending 상태)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
            'student_id': _studentIdCtrl.text.trim(),
            'email': email,
            'name': fullName, // 전체 이름
            'last_name': lastName, // 성
            'first_name': firstName, // 이름
            'role': 'USER',
            'status': 'pending', // 승인 대기
            'proof_url': proofUrl, // 증명서 URL
            'created_at': FieldValue.serverTimestamp(),
            'approved_at': null,
            'expires_at': null,
          });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => CustomDialog(
            title: "가입 신청 완료",
            contentText: "회원가입 신청이 완료되었습니다.\n학생회에서 재학 정보를 확인한 후\n승인하면 로그인이 가능합니다.\n(최대 3일 소요)",
            confirmText: "확인",
            onConfirm: () {
              Navigator.pop(ctx); // 다이얼로그 닫기
              Navigator.pop(context); // 로그인 화면으로 돌아가기
            },
          ),
        );
      }
    } catch (e) {
      String message = "가입 실패: $e";
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        message = "이미 가입된 학번(이메일)입니다.";
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
                  "재학 여부 확인을 위해\n재학증명 서류 또는 이미지를 첨부해주세요.",
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
                    color: Color(0xFFB0B8C1),
                  ),
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
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "영문+숫자 포함 8자리 이상",
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
                    Icons.lock_outline_rounded,
                    color: Color(0xFFB0B8C1),
                  ),
                ),
              ),

              // 4. 재학증명서 업로드 UI
              const Text(
                "재학 증명 서류 또는 이미지 첨부",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 8),
              Bounceable(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E8EB)),
                  ),
                  alignment: Alignment.center,
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: Color(0xFFB0B8C1)),
                            SizedBox(height: 8),
                            Text(
                              "이미지 추가하기",
                              style: TextStyle(
                                  color: Color(0xFF8B95A1), fontSize: 13),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _imageFile!,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),

              // 5. 가입 버튼
              Bounceable(
                onTap: _isLoading ? null : _signUp,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3182F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CustomLoadingIndicator(
                          color: Colors.white,
                          size: 20,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
