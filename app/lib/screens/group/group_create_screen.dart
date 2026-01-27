import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // NEW
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/common/custom_dialog.dart';
import '../../widgets/common/bounceable.dart';

class GroupCreateScreen extends StatefulWidget {
  // ... (rest of class)

  // ★ 추가: 생성이 완료되면 호출할 콜백 함수
  final VoidCallback? onGroupCreated;

  const GroupCreateScreen({super.key, this.onGroupCreated});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _linkController = TextEditingController();

  bool _isLoading = false;
  bool _isAdmin = false; // ★ 관리자 여부
  bool _isOfficial = false; // ★ 공식 글 체크 여부

  double _maxMembers = 4;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    String role = await FirestoreService().getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = (role == 'ADMIN');
      });
    }
  }

  Future<void> _createGroup() async {
    if (_titleController.text.isEmpty) {
      ToastUtils.show(context, "제목을 입력해주세요.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    List<String> tags = _tagController.text
        .trim()
        .split(' ')
        .map((e) {
          if (e.isEmpty) return '';
          return e.startsWith('#') ? e : '#$e';
        })
        .where((e) => e.isNotEmpty)
        .toList();

    if (tags.isEmpty) tags = ['#모집'];

    try {
      await FirestoreService().createGroup(
        title: _titleController.text,
        content: _contentController.text,
        hashtags: tags,
        deadline: _deadline,
        maxMembers: _maxMembers >= 21 ? -1 : _maxMembers.toInt(),
        linkUrl: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
        isOfficial: _isOfficial, // ★ 공식 여부 전달
      );

      if (mounted) {
        // ★ 요청하신 멘트로 수정
        ToastUtils.show(context, "모집 만들기를 완료했어요.");

        // 입력창 초기화
        _titleController.clear();
        _contentController.clear();
        _tagController.clear();
        _linkController.clear();
        setState(() {
          _maxMembers = 4;
          _deadline = DateTime.now().add(const Duration(days: 7));
        });

        // ★ 핵심: 모임 관리 페이지로 이동하라는 신호 보내기
        widget.onGroupCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, "잠시 오류가 발생했어요.: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("제목"),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: "제목을 입력해주세요",
              hintStyle: TextStyle(color: Color(0xFFC5C8CE)), // 흐릿하게
              filled: true,
              fillColor: Colors.white,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3182F6)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel("모집 목적 (해시태그)"),
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(
              hintText: "예: 스터디 코딩 java (띄어쓰기로 구분)",
              hintStyle: TextStyle(color: Color(0xFFC5C8CE)), // 흐릿하게
              filled: true,
              fillColor: Colors.white,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3182F6)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel("모집 인원"),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E8EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxMembers,
                    min: 1,
                    max: 21, // 21을 '제한 없음'으로 사용
                    divisions: 20,
                    activeColor: const Color(0xFF3182F6),
                    onChanged: (val) => setState(() => _maxMembers = val),
                  ),
                ),
                Bounceable(
                  onTap: () async {
                    final TextEditingController controller =
                        TextEditingController.fromValue(
                          TextEditingValue(
                            text: _maxMembers >= 21
                                ? ""
                                : _maxMembers.toInt().toString(),
                            selection: TextSelection.collapsed(
                              offset: _maxMembers >= 21
                                  ? 0
                                  : _maxMembers.toInt().toString().length,
                            ),
                          ),
                        );

                    await showDialog(
                      context: context,
                      builder: (context) {
                        return CustomDialog(
                          title: "인원 수 직접 입력",
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: "숫자만 입력 (21 이상은 제한없음)",
                              suffixText: "명",
                            ),
                          ),
                          cancelText: "취소",
                          confirmText: "확인",
                          onCancel: () => Navigator.pop(context),
                          onConfirm: () {
                            if (controller.text.isNotEmpty) {
                              double? val = double.tryParse(controller.text);
                              if (val != null) {
                                if (val < 1) val = 1;
                                if (val > 21) val = 21;
                                setState(() => _maxMembers = val!);
                              }
                            }
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _maxMembers >= 21 ? "제한 없음" : "${_maxMembers.toInt()}명",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333D4B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel("마감 기한"),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E8EB)), // ★ 보더 추가
            ),
            child: ListTile(
              title: Text(DateFormat('yyyy년 MM월 dd일').format(_deadline)),
              trailing: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF3182F6),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _deadline = date);
              },
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel("신청 링크 (선택사항)"),
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
              hintText: "구글폼, 오픈채팅방 링크 (비워두기 가능)",
              hintStyle: TextStyle(color: Color(0xFFC5C8CE)), // 흐릿하게
              filled: true,
              fillColor: Colors.white,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3182F6)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const SizedBox(height: 16),

          // ★ 관리자 전용: 공식 글 체크박스
          if (_isAdmin)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3182F6).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _isOfficial,
                    activeColor: const Color(0xFF3182F6),
                    onChanged: (val) {
                      setState(() {
                        _isOfficial = val ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "공식(학생회) 모집글로 등록하기",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3182F6),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          _buildLabel("내용"),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "모집 상세 설명",
              hintStyle: TextStyle(color: Color(0xFFB0B8C1)), // 흐릿하게
              filled: true,
              fillColor: Colors.white,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3182F6)),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 40),

          ElasticIn(
            // Toss-style bounce
            delay: const Duration(milliseconds: 300),
            child: SizedBox(
              width: double.infinity,
              child: Bounceable(
                onTap: _isLoading ? null : _createGroup,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3182F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "모집 만들기",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4E5968),
        ),
      ),
    );
  }
}
