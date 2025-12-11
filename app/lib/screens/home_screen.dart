import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/event.dart';
import 'welcome_screen.dart';
import '../widgets/home/urgent_notice_widget.dart';
import '../widgets/home/important_notice_widget.dart'; // NEW
import '../widgets/home/hot_notice_widget.dart';
import '../widgets/home/category_grid_widget.dart';
import '../models/home_widget_config.dart';
import 'widget_management_screen.dart';
import 'admin/write_notice_screen.dart'; // NEW
import 'admin/admin_notice_management_screen.dart'; // NEW

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Map<String, Stream<int>> _noticeStreams;

  // 기본 위젯 설정 (초기값 및 폴백)
  final List<HomeWidgetConfig> _defaultWidgets = [
    HomeWidgetConfig(id: 'urgent_notice', isVisible: true),
    HomeWidgetConfig(id: 'important_notice', isVisible: true), // NEW
    HomeWidgetConfig(id: 'calendar', isVisible: true),
    HomeWidgetConfig(id: 'categories', isVisible: true),
    HomeWidgetConfig(id: 'hot_notice', isVisible: true),
  ];

  List<HomeWidgetConfig> _currentWidgets = [];
  bool _isLoadingWidgets = true;
  String _userRole = ''; // NEW

  @override
  void initState() {
    super.initState();
    _loadWidgetConfig();

    // 권한 가져오기
    _firestoreService.getUserRole().then((role) {
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    });

    _noticeStreams = {
      "긴급": _firestoreService.getNoticeCount("긴급"),
      "학사": _firestoreService.getNoticeCount("학사"),
      "장학": _firestoreService.getNoticeCount("장학"),
      "취업": _firestoreService.getNoticeCount("취업"),
      "행사": _firestoreService.getNoticeCount("행사"),
      "광고": _firestoreService.getNoticeCount("광고"),
    };
  }

  void _loadWidgetConfig() {
    // 위젯 설정 구독
    _firestoreService.getHomeWidgetConfig().listen((configMaps) {
      if (!mounted) return;

      setState(() {
        if (configMaps.isEmpty) {
          _currentWidgets = List.from(_defaultWidgets);
        } else {
          // Firestore에 저장된 설정 불러오기
          List<HomeWidgetConfig> loaded = configMaps
              .map((m) => HomeWidgetConfig.fromMap(m))
              .toList();

          // 기본 위젯 누락 방지 로직
          List<HomeWidgetConfig> merged = List.from(loaded);
          for (var def in _defaultWidgets) {
            if (!merged.any((w) => w.id == def.id)) {
              merged.add(def);
            }
          }
          _currentWidgets = merged;
        }
        _isLoadingWidgets = false;
      });
    });
  }

  bool _isEditMode = false; // NEW: 편집 모드 상태

  @override
  Widget build(BuildContext context) {
    // 보여줄 위젯 리스트 (순서대로)
    final visibleWidgets = _currentWidgets.where((c) => c.isVisible).toList();
    // 숨겨진 위젯 리스트
    final hiddenWidgets = _currentWidgets.where((c) => !c.isVisible).toList();

    return Scaffold(
      drawer: _buildSideMenu(context),
      backgroundColor: _isEditMode
          ? const Color(0xFFE0E0E0)
          : const Color(0xFFF2F4F6), // White -> F2F4F6
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF2F4F6), // White -> F2F4F6
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF4E5968)),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          '홈',
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        actions: [
          // 편집 모드 토글 버튼
          if (!_isEditMode)
            IconButton(
              icon: const Icon(
                Icons.open_with_rounded,
                color: Color(0xFF4E5968),
              ), // 연필 -> 4방향 화살표
              tooltip: "홈 화면 편집",
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
            ),

          // 편집 완료 버튼 (편집 모드일 때만 표시)
          if (_isEditMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                });
                _saveWidgetConfig(); // 변경사항 저장
              },
              child: const Text(
                "완료",
                style: TextStyle(
                  color: Color(0xFF3182F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF4E5968),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoadingWidgets
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView(
              buildDefaultDragHandles: false, // 기본 드래그 핸들 비활성화 (조건부 적용 위해)
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              header: _isEditMode
                  ? _buildAddWidgetHeader(hiddenWidgets) // 위젯 추가 버튼 영역
                  : const SizedBox.shrink(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = visibleWidgets.removeAt(oldIndex);
                  visibleWidgets.insert(newIndex, item);
                  _currentWidgets = [...visibleWidgets, ...hiddenWidgets];
                });
              },
              children: [
                for (int i = 0; i < visibleWidgets.length; i++)
                  _buildDraggableItem(
                    visibleWidgets[i],
                    Key(visibleWidgets[i].id),
                    i, // index 전달
                  ),
              ],
            ),
    );
  }

  // ... (Header parts skipped, assumed unchanged or handled by partial replacement if needed,
  // but here we are replacing build method primarily so Header helper is fine if outside range,
  // wait, range 124 to 349 covers build method and _buildDraggableItem)

  // ... Oops I need to include _buildDraggableItem in the ReplacementContent
  // since I am replacing the whole block including it?
  // The Range 124-349 covers `actions` to `_buildDraggableItem`.
  // I must provide _buildAddWidgetHeader and _getWidgetName if they act as spacer or just leave them if not in range.
  // Actually, I should split this into two replacements or include everything in between.
  // Let's replace the `build` method and `_buildDraggableItem`.
  // Intermediate methods `_buildAddWidgetHeader` and `_getWidgetName` are between `build` and `_buildDraggableItem`.
  // I will include them unmodified in the replacement content to be safe or use separate calls.
  // Using MultiReplace is better if they are far apart.
  // They are contigous in file: `build` -> `_buildAddWidgetHeader` -> `_getWidgetName` -> `_buildDraggableItem`.
  // I will replace all of them.

  // ... (Rest of ReplacementContent)

  // 위젯 추가 헤더 (+ 버튼)
  Widget _buildAddWidgetHeader(List<HomeWidgetConfig> hiddenWidgets) {
    if (hiddenWidgets.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: hiddenWidgets.map((config) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      config.isVisible = true;
                      _currentWidgets.remove(config);
                      _currentWidgets.insert(0, config);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3182F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_rounded,
                          color: Color(0xFF3182F6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getWidgetName(config.id),
                          style: const TextStyle(
                            color: Color(0xFF3182F6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
        ],
      ),
    );
  }

  String _getWidgetName(String id) {
    switch (id) {
      case 'urgent_notice':
        return '긴급 공지';
      case 'important_notice':
        return '중요 공지';
      case 'calendar':
        return '오늘의 일정';
      case 'categories':
        return '카테고리';
      case 'hot_notice':
        return 'HOT 공지';
      default:
        return '위젯';
    }
  }

  // 드래그 가능한 아이템 래퍼 (X 버튼 포함)
  Widget _buildDraggableItem(HomeWidgetConfig config, Key key, int index) {
    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        // 실제 위젯 콘텐츠
        AbsorbPointer(
          absorbing: _isEditMode, // 편집 모드일 때 내부 터치 비활성화 (드래그 용이)
          child: _buildWidgetContent(config.id),
        ),

        // 편집 모드 UI (삭제 버튼 + 드래그 딤드/핸들 효과)
        if (_isEditMode) ...[
          // 컨텐츠 위에 살짝 덮는 투명 레이어 (터치 인터셉트용)
          Positioned.fill(child: Container(color: Colors.transparent)),

          // 삭제 버튼
          Positioned(
            top: -12,
            right: -8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  config.isVisible = false;
                  _saveWidgetConfig();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF5350), // Red
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    // 전체 컨테이너 (여백 포함)
    Widget itemContainer = Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: content,
    );

    // 편집 모드일 때: 드래그 리스너 적용 (KEY 필수)
    if (_isEditMode) {
      return ReorderableDragStartListener(
        key: key, // ★ 핵심: Key를 여기에 전달
        index: index,
        child: itemContainer,
      );
    }

    // 일반 모드일 때: 롱프레스 감지 (KEY 필수)
    return GestureDetector(
      key: key, // ★ 핵심: Key를 여기에 전달
      onLongPress: () {
        setState(() {
          _isEditMode = true;
        });
        // 햅틱 피드백 (선택 사항)
      },
      child: itemContainer,
    );
  }

  // 위젯 ID -> 위젯 매핑
  Widget _buildWidgetContent(String id) {
    switch (id) {
      case 'urgent_notice':
        return UrgentNoticeWidget(forceShow: _isEditMode);
      case 'important_notice':
        return ImportantNoticeWidget(forceShow: _isEditMode);
      case 'calendar':
        return _buildTodaySchedule();
      case 'categories':
        return CategoryGridWidget(firestoreService: _firestoreService);
      case 'hot_notice':
        return HotNoticeWidget(forceShow: _isEditMode);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _saveWidgetConfig() async {
    List<Map<String, dynamic>> configList = _currentWidgets
        .map((e) => e.toMap())
        .toList();
    await _firestoreService.saveHomeWidgetConfig(configList);
  }

  Widget _buildSideMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: const Color(0xFFF2F4F6),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          StreamBuilder<DocumentSnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots()
                : null,
            builder: (context, snapshot) {
              String name = ''; // 로딩 중에는 빈 값
              String studentId = '';

              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  name = "${data['last_name']}${data['first_name']}님";
                  studentId = "${data['student_id']}";
                }
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E8EB), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5E8EB),
                          width: 1,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFFF2F4F6),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: Color(0xFFB0B8C1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name.isEmpty ? '불러오는 중...' : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF191F28),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studentId,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8B95A1),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
          _buildDrawerItem(Icons.person_outline_rounded, '내 정보 관리', () {
            // 내 정보 관리 페이지로 이동
          }),
          _buildDrawerItem(Icons.dashboard_customize_rounded, '홈 위젯 관리', () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WidgetManagementScreen(),
              ),
            );
          }),
          // 관리자 메뉴
          if (_userRole == 'ADMIN') ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                "관리자 메뉴",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            _buildDrawerItem(Icons.edit_calendar_rounded, '공지사항 작성', () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WriteNoticeScreen(),
                ),
              );
            }),
            _buildDrawerItem(Icons.list_alt_rounded, '공지사항 관리', () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminNoticeManagementScreen(),
                ),
              );
            }),
          ],
          _buildDrawerItem(Icons.notifications_active_rounded, '알림 설정', () {
            // 알림 설정 다이얼로그 표시
            showDialog(
              context: context,
              builder: (context) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    bool isEnabled = true; // 기본값
                    if (snapshot.hasData && snapshot.data!.exists) {
                      isEnabled =
                          (snapshot.data!.data()
                              as Map<String, dynamic>)['isPushEnabled'] ??
                          true;
                    }

                    return AlertDialog(
                      title: const Text("알림 설정"),
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("푸시 알림 받기"),
                          Switch(
                            value: isEnabled,
                            onChanged: (val) {
                              _firestoreService.togglePushSetting(val);
                              // StreamBuilder will auto update UI
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("닫기"),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }),
          _buildDrawerItem(Icons.logout_rounded, '로그아웃', () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            }
          }, color: const Color(0xFF3182F6)),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF4E5968)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color ?? const Color(0xFF333D4B),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildTodaySchedule() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateText = "${now.month}월 ${now.day}일 (${_getDayName(now.weekday)})";

    return StreamBuilder<List<Event>>(
      stream: _firestoreService.getEvents(),
      builder: (context, snapshot) {
        List<Event> todayEvents = [];
        if (snapshot.hasData) {
          todayEvents = snapshot.data!.where((event) {
            final startDate = DateTime(
              event.startDate.year,
              event.startDate.month,
              event.startDate.day,
            );
            final endDate = DateTime(
              event.endDate.year,
              event.endDate.month,
              event.endDate.day,
            );
            return (today.isAfter(startDate) ||
                    today.isAtSameMomentAs(startDate)) &&
                (today.isBefore(endDate) || today.isAtSameMomentAs(endDate));
          }).toList();
          todayEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
        }

        Widget eventContent;
        if (todayEvents.isEmpty) {
          eventContent = const Text(
            "오늘은 일정이 없어요.",
            style: TextStyle(fontSize: 15, color: Color(0xFF8B95A1)),
          );
        } else {
          List<Widget> eventWidgets = [];
          for (int i = 0; i < todayEvents.length && i < 5; i++) {
            final event = todayEvents[i];
            eventWidgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: event.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 15, // 제목표준 : 15
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333D4B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 5개 초과 시 '그 외 N개' 표시
          if (todayEvents.length > 5) {
            eventWidgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  "+ 그 외 ${todayEvents.length - 5}개 일정",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8B95A1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          eventContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: eventWidgets,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE5E8EB)), // ★ 회색 보더로 복구
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "오늘의 일정",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF3182F6), // 토스 블루
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191F28),
                      ),
                    ),
                    const SizedBox(height: 16),
                    eventContent,
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 오른쪽 미니 달력
              Expanded(
                flex: 3,
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: now,
                  calendarFormat: CalendarFormat.month,
                  headerVisible: false,
                  daysOfWeekHeight: 20,
                  rowHeight: 40,

                  eventLoader: (day) {
                    if (!snapshot.hasData) return [];
                    final events = snapshot.data!;
                    return events.where((e) {
                      DateTime checkDay = DateTime(
                        day.year,
                        day.month,
                        day.day,
                      );
                      DateTime start = DateTime(
                        e.startDate.year,
                        e.startDate.month,
                        e.startDate.day,
                      );
                      DateTime end = DateTime(
                        e.endDate.year,
                        e.endDate.month,
                        e.endDate.day,
                      );

                      return (checkDay.isAfter(start) ||
                              checkDay.isAtSameMomentAs(start)) &&
                          (checkDay.isBefore(end) ||
                              checkDay.isAtSameMomentAs(end));
                    }).toList();
                  },

                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF3182F6), // 오늘 날짜: 브랜드 블루
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5E8EB),
                        width: 1.5,
                      ),
                    ),
                    todayTextStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.white, // 파란 배경이므로 흰색 텍스트
                      fontWeight: FontWeight.bold,
                    ),
                    // 홈 화면은 날짜 선택 기능이 없으므로 selectedDecoration은 기본값 유지 혹은 숨김
                    selectedDecoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(fontSize: 13),
                    weekendTextStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                    ),
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(2.0),
                  ),

                  // ★ 핵심: 미니 달력에도 카테고리 색상 적용
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
                        color = Colors.grey; // 미니 달력 평일: 그레이 (기존 스타일 유지)
                      }
                      return Center(
                        child: Text(
                          text,
                          style: TextStyle(fontSize: 11, color: color),
                        ),
                      );
                    },
                    // 주말 및 평일 날짜 커스텀 (weekendBuilder가 없을 수 있으므로 defaultBuilder 사용)
                    defaultBuilder: (context, day, focusedDay) {
                      if (day.weekday == DateTime.saturday) {
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF3182F6),
                            ),
                          ),
                        );
                      } else if (day.weekday == DateTime.sunday) {
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      return null; // 평일은 기본 스타일 사용
                    },
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: events.take(3).map((e) {
                          // e는 Object 타입이므로 Event로 형변환
                          final event = e as Event;
                          return Container(
                            width: 4, // 미니 달력이라 조금 작게(4px)
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: event.color, // ★ 색상 적용
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekendStyle: TextStyle(fontSize: 11, color: Colors.grey),
                    weekdayStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "긴급":
        return const Color(0xFFFF8A80);
      case "학사":
        return const Color(0xFF82B1FF);
      case "장학":
        return const Color(0xFFFFD180);
      case "취업":
        return const Color(0xFFA5D6A7);
      case "행사":
        return const Color(0xFFCE93D8);
      case "광고":
        return const Color(0xFFB0BEC5);
      default:
        return const Color(0xFF3182F6);
    }
  }
}
