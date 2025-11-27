// lib/group_create_screen.dart
import 'package:flutter/material.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  double _memberCount = 4.0; // 모집 인원 (기본 4명)
  DateTime? _selectedDate; // 마감 기한

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        title: const Text('모임 만들기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김 (하단바로 제어)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('제목'),
            _buildTextField('제목을 입력해주세요'),
            
            const SizedBox(height: 24),
            _buildLabel('모집 목적 (해시태그)'),
            _buildTextField('예: 스터디 코딩 java'),

            const SizedBox(height: 24),
            _buildLabel('모집 인원 (최대 20명)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF3B82F6),
                        inactiveTrackColor: Colors.blue[100],
                        thumbColor: const Color(0xFF3B82F6),
                        overlayColor: Colors.blue.withAlpha(32),
                      ),
                      child: Slider(
                        value: _memberCount,
                        min: 2,
                        max: 20,
                        divisions: 18,
                        onChanged: (value) {
                          setState(() {
                            _memberCount = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${_memberCount.toInt()}명',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildLabel('마감 기한'),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2026),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? '날짜를 선택해주세요'
                          : '${_selectedDate!.year}년 ${_selectedDate!.month}월 ${_selectedDate!.day}일',
                      style: TextStyle(
                        color: _selectedDate == null ? Colors.grey[400] : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF3B82F6)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildLabel('신청 링크 (선택사항)'),
            _buildTextField('구글폼, 오픈채팅방 링크 (비워두기 가능)'),

            const SizedBox(height: 24),
            _buildLabel('내용'),
            Container(
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const TextField(
                maxLines: null,
                decoration: InputDecoration.collapsed(
                  hintText: '모임 상세 설명',
                  hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('모임 만들기 완료', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF616161))),
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}