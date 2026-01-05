import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/group.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/common/custom_loading_indicator.dart';

class GroupEditScreen extends StatefulWidget {
  final Group group;
  final VoidCallback? onGroupUpdated;

  const GroupEditScreen({super.key, required this.group, this.onGroupUpdated});

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late TextEditingController _linkController;

  bool _isLoading = false;
  bool _isAdmin = false;
  late bool _isOfficial;
  late double _maxMembers;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    _initializeFields();
  }

  void _initializeFields() {
    _titleController = TextEditingController(text: widget.group.title);
    _contentController = TextEditingController(text: widget.group.content);
    // 태그 리스트를 문자열로 변환 (예: ["#스터디", "#자바"] -> "#스터디 #자바")
    _tagController =
        TextEditingController(text: widget.group.hashtags.join(' '));
    _linkController = TextEditingController(text: widget.group.linkUrl ?? '');
    _isOfficial = widget.group.isOfficial;
    _maxMembers =
        widget.group.maxMembers == -1 ? 21 : widget.group.maxMembers.toDouble();
    _deadline = widget.group.deadline;
  }

  Future<void> _checkAdminRole() async {
    String role = await FirestoreService().getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = (role == 'ADMIN');
      });
    }
  }

  Future<void> _updateGroup() async {
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
      await FirestoreService().updateGroup(
        groupId: widget.group.id,
        title: _titleController.text,
        content: _contentController.text,
        hashtags: tags,
        deadline: _deadline,
        maxMembers: _maxMembers >= 21 ? -1 : _maxMembers.toInt(),
        linkUrl: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
        isOfficial: _isOfficial,
      );

      if (mounted) {
        ToastUtils.show(context, "모집 내용이 수정되었어요.");
        widget.onGroupUpdated?.call();
        Navigator.pop(context); // 수정 완료 후 뒤로 가기
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, "수정 중 오류가 발생했어요: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text(
          "모집 수정",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("제목"),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "제목을 입력해주세요",
                hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
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
                hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
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
                      max: 21,
                      divisions: 20,
                      activeColor: const Color(0xFF3182F6),
                      onChanged: (val) => setState(() => _maxMembers = val),
                    ),
                  ),
                  Text(
                    _maxMembers >= 21 ? "제한 없음" : "${_maxMembers.toInt()}명",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
                border: Border.all(color: const Color(0xFFE5E8EB)),
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
                hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
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

            if (_isAdmin)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                hintStyle: TextStyle(color: Color(0xFFB0B8C1)),
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CustomLoadingIndicator(color: Colors.white)
                    : const Text(
                        "수정 완료",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
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
