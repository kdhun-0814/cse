// screens/admin/event_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart'; // Event 모델 import
import '../../services/firestore_service.dart';

class EventEditScreen extends StatefulWidget {
  final Event event; // 수정할 이벤트 객체

  const EventEditScreen({super.key, required this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _titleController = TextEditingController();
  late String _category;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  final List<String> _categories = ["학사", "장학", "행사", "취업", "휴일"];

  @override
  void initState() {
    super.initState();
    // 기존 데이터로 초기화
    _titleController.text = widget.event.title;
    _category = widget.event.category;
    _startDate = widget.event.startDate;
    _endDate = widget.event.endDate;

    // 카테고리 목록에 없는 값이 들어있을 경우 대비
    if (!_categories.contains(_category)) {
      _category = _categories[0];
    }
  }

  Future<void> _updateEvent() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await FirestoreService().updateEvent(
        eventId: widget.event.id, // ID 필수
        title: _titleController.text,
        category: _category,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("수정 완료!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("수정 실패")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "일정 수정",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "제목",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF2F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "카테고리",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  items: _categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => _category = newValue!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "기간 설정",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildDatePicker(
              "시작일",
              _startDate,
              (date) => setState(() => _startDate = date),
            ),
            const SizedBox(height: 12),
            _buildDatePicker(
              "종료일",
              _endDate,
              (date) => setState(() => _endDate = date),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "수정 완료",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime date,
    Function(DateTime) onPicked,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('yyyy년 MM월 dd일').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Color(0xFF3182F6),
            ),
          ],
        ),
      ),
    );
  }
}
