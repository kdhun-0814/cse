import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'package:flutter_slidable/flutter_slidable.dart'; // 삭제
import '../models/event.dart';
import '../services/firestore_service.dart';
// import '../utils/toast_utils.dart'; // 삭제 (confirmDelete 이동으로 불필요할 수 있음, 하지만 다른데 쓸 수 있으니 확인)
import '../widgets/common/custom_loading_indicator.dart';
// import 'admin/event_add_screen.dart'; // 삭제 (관리 페이지로 이동)
// import 'admin/event_edit_screen.dart'; // 삭제 (관리 페이지로 이동)
import 'admin/event_management_screen.dart'; // ★ 관리 페이지 import

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _kEventSource = {};

  // 스트림 캐싱을 위한 변수
  late Stream<List<Event>> _eventsStream;

  // 관리자 여부 확인용 변수
  bool _isAdmin = false;

  // 권한 확인 함수
  Future<void> _checkAdminRole() async {
    String role = await _firestoreService.getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = (role == 'ADMIN');
      });
    }
  }

  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventsStream = _firestoreService.getEvents(); // ★ 스트림 초기화
    _checkAdminRole();

    // 스크롤 리스너 추가 (구분선 로직)
    _scrollController.addListener(() {
      if (_scrollController.offset > 10) {
        if (!_isScrolled) setState(() => _isScrolled = true);
      } else {
        if (_isScrolled) setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ... (이벤트 로더, 날짜 선택 로직 등 기존과 동일) ...
  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _kEventSource[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  // 삭제 확인 다이얼로그 제거됨 (EventManagementScreen으로 이동)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '학과 일정',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF191F28),
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0, // 스크롤 시 색상 변경 방지
        surfaceTintColor: Colors.transparent, // 틴트 컬러 제거
        shape: _isScrolled
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE5E8EB), width: 1),
              )
            : null,
        backgroundColor: const Color(0xFFF2F4F6),
        actions: [
          // 상단 설정 버튼 (관리자일 때만 보임)
          if (_isAdmin)
            IconButton(
              icon: const Icon(
                Icons.settings_outlined, // 톱니바퀴 아이콘
                color: Color(0xFF3182F6),
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EventManagementScreen(),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: _eventsStream, // ★ 캐싱된 스트림 사용
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("일정을 불러오지 못했습니다."));
          }

          // 데이터 매핑 로직 (기존과 동일)
          final events = snapshot.data ?? [];
          _kEventSource = {};
          for (var event in events) {
            DateTime date = event.startDate;
            DateTime endCheck = DateTime(
              event.endDate.year,
              event.endDate.month,
              event.endDate.day,
            );
            while (!DateTime(
              date.year,
              date.month,
              date.day,
            ).isAfter(endCheck)) {
              final dateKey = DateTime(date.year, date.month, date.day);
              if (_kEventSource[dateKey] == null) _kEventSource[dateKey] = [];
              _kEventSource[dateKey]!.add(event);
              date = date.add(const Duration(days: 1));
            }
          }

          final selectedEvents = _getEventsForDay(_selectedDay!);

          return Column(
            children: [
              // 1. 캘린더 영역 (기존과 동일)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE5E8EB), // ★ 회색 보더
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar<Event>(
                  locale: 'ko_KR', // 한국어 달력 ("2025년 12월")
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.grey[200], // 오늘 날짜: 연회색 (배경색)
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: Color(0xFF333D4B),
                      fontWeight: FontWeight.bold,
                    ), // 오늘 날짜 텍스트: 진한 회색 (잘 보이게)
                    selectedDecoration: BoxDecoration(
                      color: const Color(0xFF3182F6), // 선택된 날짜: 브랜드 블루
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5E8EB),
                        width: 1.5,
                      ), // ★ 보더 추가
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ), // 선택된 날짜 텍스트: 흰색 (명시적 지정)
                    defaultTextStyle: const TextStyle(color: Color(0xFF333D4B)),
                    weekendTextStyle: const TextStyle(color: Colors.red),
                    cellMargin: const EdgeInsets.all(
                      9.0,
                    ), // 원 크기 축소 (여백 6 -> 9)
                  ),
                  calendarBuilders: CalendarBuilders(
                    // 요일 헤더 커스텀 (토: 파랑, 일: 빨강, 평일: 한글+회색)
                    dowBuilder: (context, day) {
                      final text = const [
                        '월',
                        '화',
                        '수',
                        '목',
                        '금',
                        '토',
                        '일',
                      ][day.weekday - 1];
                      Color color;
                      if (day.weekday == DateTime.saturday) {
                        color = const Color(0xFF3182F6);
                      } else if (day.weekday == DateTime.sunday) {
                        color = Colors.red;
                      } else {
                        color = const Color(0xFF333D4B); // 평일: 다크 그레이
                      }
                      return Center(
                        child: Text(text, style: TextStyle(color: color)),
                      );
                    },
                    // 주말 및 평일 날짜 커스텀
                    defaultBuilder: (context, day, focusedDay) {
                      if (day.weekday == DateTime.saturday) {
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Color(0xFF3182F6)),
                          ),
                        );
                      } else if (day.weekday == DateTime.sunday) {
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return null; // 평일은 기본 스타일
                    },
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.take(3).map((e) {
                          final event = e;
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: event.color,
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  onDaySelected: _onDaySelected,
                ),
              ),
              const SizedBox(height: 20),

              // 2. 하단 리스트 영역 (★ 수정됨: Slidable 적용)
              Expanded(
                child: selectedEvents.isEmpty
                    ? const Center(
                        child: Text(
                          "등록된 일정이 없습니다.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];

                          // 리스트 아이템 디자인 (기존 코드를 함수로 분리하거나 변수로 저장)
                          Widget itemContent = Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.hardEdge, // 둥근 모서리에 색상 띠가 잘리도록
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E8EB),
                              ), // 전체 회색 보더
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    width: 6,
                                    color: event.color,
                                  ), // 왼쪽 색상 띠
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  event.title,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF333D4B),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  event.category,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: event.color,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            event.dateRangeText,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          // ★ 관리자여도 CalendarScreen에서는 수정/삭제 불가 (EventManagementScreen에서 수행)
                          // 따라서 항상 기본 itemContent 반환
                          return itemContent;
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
