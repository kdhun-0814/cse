import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return kEvents[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학과 일정', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF191F28))),
        elevation: 0,
        backgroundColor: const Color(0xFFF2F4F6),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: Color(0xFF3182F6)), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 20),
            child: TableCalendar<Event>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false, titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              
              // ★ 캘린더 스타일 수정 (투명도 적용)
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: const Color.fromARGB(255, 188, 55, 55).withOpacity(0.3), shape: BoxShape.circle),
                // 선택된 날짜 파란색 투명도 30%
                selectedDecoration: BoxDecoration(color: const Color(0xFF3182F6).withOpacity(0.2), shape: BoxShape.circle),
                // 이벤트 마커 파란색 투명도 50%
                markerDecoration: BoxDecoration(color: const Color(0xFF3182F6).withOpacity(0.8), shape: BoxShape.circle),
              ),
              onDaySelected: _onDaySelected,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) return const Center(child: Text("등록된 일정이 없습니다.", style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: event.color, width: 6))),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333D4B))),
                              const SizedBox(height: 4),
                              Text(event.category, style: TextStyle(fontSize: 12, color: event.color, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Spacer(),
                          const Text("All Day", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}