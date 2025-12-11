import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // ★ 패키지 import
import '../models/event.dart';
import '../services/firestore_service.dart';
import 'admin/event_add_screen.dart';
import 'admin/event_edit_screen.dart'; // ★ 수정 화면 import

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

  // 삭제 확인 다이얼로그
  void _confirmDelete(Event event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("일정 삭제"),
        content: const Text("정말로 이 일정을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteEvent(event.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
              }
            },
            child: const Text(
              "삭제",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

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
          // 상단 + 버튼 (관리자일 때만 보임)
          if (_isAdmin)
            IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: Color(0xFF3182F6),
                size: 32,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EventAddScreen(),
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
            return const Center(child: CircularProgressIndicator());
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
                          final event = e as Event;
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

                          // ★ 관리자가 아니면 그냥 아이템 반환
                          if (!_isAdmin) return itemContent;

                          // ★ 관리자면 Slidable로 감싸서 반환
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ), // Slidable 간격 조정
                            child: Slidable(
                              key: ValueKey(event.id),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                extentRatio: 0.5, // 버튼들이 차지할 비율
                                children: [
                                  CustomSlidableAction(
                                    onPressed: (context) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EventEditScreen(event: event),
                                        ),
                                      );
                                    },
                                    backgroundColor: const Color(
                                      0xFF90CAF9,
                                    ), // 학사 색상 (파스텔 블루)
                                    foregroundColor: Colors.white,
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(16),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFE5E8EB),
                                        ),
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              left: Radius.circular(16),
                                            ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.edit_rounded, size: 28),
                                          SizedBox(height: 4),
                                          Text(
                                            "수정 (관리자)",
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  CustomSlidableAction(
                                    onPressed: (context) {
                                      _confirmDelete(event);
                                    },
                                    backgroundColor: const Color(
                                      0xFFEF9A9A,
                                    ), // 긴급 색상 (파스텔 레드)
                                    foregroundColor: Colors.white,
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(16),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFE5E8EB),
                                        ),
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              right: Radius.circular(16),
                                            ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 28,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "삭제 (관리자)",
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              child: Container(
                                // Slidable child 안쪽에는 margin을 없애야 자연스러움 (Slidable 밖인 Padding에서 처리)
                                margin: EdgeInsets.zero,
                                child: itemContent,
                              ),
                            ),
                          );
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
