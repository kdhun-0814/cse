import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/group.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _linkController = TextEditingController();
  
  double _maxMembers = 4;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));

  void _createGroup() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("제목을 입력해주세요.")));
      return;
    }

    List<String> tags = _tagController.text.split(' ').map((e) => e.startsWith('#') ? e : '#$e').toList();
    if (tags.isEmpty || tags[0] == '#') tags = ['#모집'];

    final newGroup = Group(
      id: DateTime.now().toString(),
      title: _titleController.text,
      content: _contentController.text,
      hashtags: tags,
      deadline: _deadline,
      maxMembers: _maxMembers.toInt(),
      linkUrl: _linkController.text.trim().isEmpty ? null : _linkController.text,
      isMyGroup: true,
    );

    setState(() {
      dummyGroups.insert(0, newGroup);
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("모임이 생성되었습니다!")));
    
    // 입력창 초기화
    _titleController.clear();
    _contentController.clear();
    _tagController.clear();
    _linkController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 없이 내용만 리턴 (RootScreen의 Body로 들어가기 때문)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 입력
          _buildLabel("제목"),
          TextField(
            controller: _titleController, 
            decoration: const InputDecoration(
              hintText: "제목을 입력해주세요",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
            )
          ),
          const SizedBox(height: 24),

          // 해시태그
          _buildLabel("모집 목적 (해시태그)"),
          TextField(
            controller: _tagController, 
            decoration: const InputDecoration(
              hintText: "예: 스터디 코딩 java",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
            )
          ),
          const SizedBox(height: 24),

          // 인원 수
          _buildLabel("모집 인원 (최대 20명)"),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxMembers,
                    min: 1, max: 20, divisions: 19,
                    activeColor: const Color(0xFF3182F6),
                    onChanged: (val) => setState(() => _maxMembers = val),
                  ),
                ),
                Text("${_maxMembers.toInt()}명", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 마감일
          _buildLabel("마감 기한"),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(DateFormat('yyyy년 MM월 dd일').format(_deadline)),
              trailing: const Icon(Icons.calendar_today_rounded, color: Color(0xFF3182F6)),
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

          // 링크
          _buildLabel("신청 링크 (선택사항)"),
          TextField(
            controller: _linkController, 
            decoration: const InputDecoration(
              hintText: "구글폼, 오픈채팅방 링크 (비워두기 가능)",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
            )
          ),
          const SizedBox(height: 24),

          // 내용
          _buildLabel("내용"),
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "모임 상세 설명",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 완료 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("모임 만들기 완료", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4E5968))),
    );
  }
}