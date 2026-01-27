import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin/admin_approval_screen.dart';
import 'settings/notification_settings_screen.dart'; // Admin Approval Screen Import
import 'package:flutter/services.dart';
import 'dart:ui'; // for lerpDouble
import 'package:table_calendar/table_calendar.dart';
import '../widgets/common/custom_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/event.dart';
import 'welcome_screen.dart';
import '../widgets/home/urgent_notice_widget.dart';
import '../widgets/home/important_notice_widget.dart'; // NEW
import '../widgets/home/hot_notice_widget.dart';
import '../widgets/home/notice_search_widget.dart'; // NEW
import '../widgets/home/cafeteria_widget.dart'; // NEW
import '../widgets/home/category_grid_widget.dart';
import '../widgets/common/custom_loading_indicator.dart';
import '../models/home_widget_config.dart';
import 'widget_management_screen.dart';
import 'admin/write_notice_screen.dart'; // NEW
import 'admin/admin_notice_management_screen.dart'; // NEW
import 'admin/admin_user_list_screen.dart'; // NEW
import 'calendar_screen.dart';
import 'notification_screen.dart';
import 'my_info_screen.dart';
import '../widgets/common/bounceable.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  // 기본 위젯 설정 (초기값 및 폴백)
  final List<HomeWidgetConfig> _defaultWidgets = [
    HomeWidgetConfig(id: 'notice_search', isVisible: true),
    HomeWidgetConfig(id: 'calendar', isVisible: true),
    HomeWidgetConfig(id: 'categories', isVisible: true),
    HomeWidgetConfig(id: 'urgent_notice', isVisible: true),
    HomeWidgetConfig(id: 'important_notice', isVisible: true),
    HomeWidgetConfig(id: 'hot_notice', isVisible: true),
  ];

  List<HomeWidgetConfig> _currentWidgets = [];
  bool _isLoadingWidgets = true;
  String _userRole = ''; // NEW

  // 스크롤 제어 및 구분선 로직
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // 플로팅 메시지 애니메이션 제어
  late AnimationController _messageController;
  late Animation<double> _messageAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    // 젤리 애니메이션 초기화 (Elastic 효과)
    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _messageAnimation = CurvedAnimation(
      parent: _messageController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );

    // 스크롤 리스너: 10px 이상 스크롤 시 구분선 표시
    _scrollController.addListener(() {
      if (_scrollController.offset > 10) {
        if (!_isScrolled) setState(() => _isScrolled = true);
      } else {
        if (_isScrolled) setState(() => _isScrolled = false);
      }
    });

    _loadWidgetConfig();

    // 권한 가져오기
    _firestoreService.getUserRole().then((role) {
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _removeOverlay(); // 안전하게 오버레이 제거
    _scrollController.dispose();
    super.dispose();
  }

  void _showFloatingMessage() {
    if (_overlayEntry != null) return; // 이미 표시 중이면 무시

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 120,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: _messageAnimation,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182F6).withOpacity(0.9), // Toss Blue
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFE5E8EB).withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3182F6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "드래그하여 순서를 조정해보세요",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // 드래그 위젯(DragProxy)보다 나중에 그려지도록 프레임 후반부에 오버레이 삽입
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry == null) return;
      Overlay.of(context).insert(_overlayEntry!);
      _messageController.forward(from: 0.0);
    });
  }

  void _hideFloatingMessage() {
    _messageController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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

  bool _isDragging = false; // 드래그 상태 추적

  @override
  Widget build(BuildContext context) {
    // 보여줄 위젯 리스트 (순서대로)
    final visibleWidgets = _currentWidgets.where((c) => c.isVisible).toList();
    // 숨겨진 위젯 리스트
    final hiddenWidgets = _currentWidgets.where((c) => !c.isVisible).toList();

    return Scaffold(
      drawer: _buildSideMenu(context),
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF2F4F6),
        shape: _isScrolled
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE5E8EB), width: 1),
              )
            : null,
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
          // 알림 아이콘 (배지 추가)
          StreamBuilder<int>(
            stream: _firestoreService.getTotalUnreadCount(),
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFF4E5968),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.dashboard_customize_rounded,
              color: Color(0xFF4E5968),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WidgetManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingWidgets
          ? const Center(child: CustomLoadingIndicator())
          : Stack(
              children: [
                ReorderableListView(
                  scrollController: _scrollController,
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final double animValue = Curves.elasticOut.transform(
                          animation.value,
                        );
                        final double scale = lerpDouble(1.0, 1.05, animValue)!;
                        return Transform.scale(
                          scale: scale,
                          child: Material(
                            color: Colors.transparent,
                            elevation: 0,
                            // Stack을 사용하여 위젯 위에 파란색 테두리 오버레이 추가
                            child: Stack(
                              children: [
                                child!,
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  bottom:
                                      24, // 아이템의 bottom margin 만큼 제외하고 테두리 표시
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        24,
                                      ), // 대략적인 위젯 반경
                                      border: Border.all(
                                        color: const Color(
                                          0xFF3182F6,
                                        ), // Toss Blue
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  onReorderStart: (index) {
                    // 드래그 시작 시 진동 및 배경 변경
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isDragging = true;
                    });
                    _showFloatingMessage(); // 오버레이 표시
                  },
                  onReorderEnd: (index) {
                    setState(() {
                      _isDragging = false;
                    });
                    _hideFloatingMessage(); // 오버레이 숨김
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = visibleWidgets.removeAt(oldIndex);
                      visibleWidgets.insert(newIndex, item);
                      _currentWidgets = [...visibleWidgets, ...hiddenWidgets];
                      _saveWidgetConfig(); // 즉시 저장
                      _isDragging = false; // 드래그 완료 처리
                    });
                    _hideFloatingMessage(); // 오버레이 숨김
                  },
                  children: [
                    for (int i = 0; i < visibleWidgets.length; i++)
                      _buildDraggableItem(
                        visibleWidgets[i],
                        Key(visibleWidgets[i].id),
                        i,
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  // 드래그 가능한 아이템 래퍼
  Widget _buildDraggableItem(HomeWidgetConfig config, Key key, int index) {
    Widget itemContainer = Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: _buildWidgetContent(config.id),
    );

    // ReorderableDelayedDragStartListener 사용으로 롱프레스 시 드래그 활성화
    return ReorderableDelayedDragStartListener(
      key: key,
      index: index,
      child: itemContainer,
    );
  }

  // 위젯 ID -> 위젯 매핑
  Widget _buildWidgetContent(String id) {
    switch (id) {
      case 'urgent_notice':
        return UrgentNoticeWidget(forceShow: false);
      case 'notice_search': // NEW
        return const NoticeSearchWidget();
      case 'important_notice':
        return ImportantNoticeWidget(forceShow: false);
      case 'cafeteria': // NEW
        return const CafeteriaWidget(forceShow: false);
      case 'calendar':
        return _buildTodaySchedule();
      case 'categories':
        return CategoryGridWidget(firestoreService: _firestoreService);
      case 'hot_notice':
        return HotNoticeWidget(forceShow: false);
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
              Map<String, dynamic>? userData;

              if (snapshot.hasData && snapshot.data != null) {
                userData = snapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null) {
                  name = "${userData!['last_name']}${userData!['first_name']} 학우님";
                  studentId = "${userData!['student_id']}";
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
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFF2F4F6),
                        backgroundImage: userData != null && userData!['profile_image_url'] != null
                            ? NetworkImage(userData!['profile_image_url'])
                            : null,
                        child: userData == null || userData!['profile_image_url'] == null
                            ? const Icon(
                                Icons.person,
                                size: 32,
                                color: Color(0xFFB0B8C1),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          name.isEmpty ? '불러오는 중...' : name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF191F28),
                          ),
                        ),
                        if (name.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: userData?['role'] == 'ADMIN'
                                  ? const Color(0xFFE8F3FF)
                                  : const Color(0xFFF2F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              userData?['role'] == 'ADMIN' ? "관리자" : "일반 학우",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: userData?['role'] == 'ADMIN'
                                    ? const Color(0xFF3182F6)
                                    : const Color(0xFF4E5968),
                              ),
                            ),
                          ),
                        ],
                      ],
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MyInfoScreen()),
            );
          }),
          _buildDrawerItem(Icons.tune_rounded, '알림 센터 설정', () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            );
          }),
          _buildDrawerItem(Icons.notifications_active_rounded, '푸시 알림 설정', () {
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

                    return CustomDialog(
                      title: "푸시 알림 설정",
                      content: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3182F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Color(0xFF3182F6),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                "공지 알림 받기",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF333D4B),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: isEnabled,
                                activeColor: const Color(0xFF3182F6),
                                onChanged: (val) {
                                  HapticFeedback.lightImpact();
                                  _firestoreService.togglePushSetting(val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmText: "닫기",
                      onConfirm: () => Navigator.pop(context),
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
          }, color: const Color(0xFF3182F6)), // 로그아웃 Brand Color
          // 관리자 메뉴
          if (_userRole == 'ADMIN') ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                "관리자 메뉴",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            _buildDrawerItem(Icons.how_to_reg_rounded, '가입 승인 관리', () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminApprovalScreen(),
                ),
              );
            }),
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
            "오늘은 일정이 없어요",
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
                          fontSize: 14, // 제목표준 : 15 -> 14로 약간 축소
                          fontWeight: FontWeight.w400, // Bold 제거
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
                    fontWeight: FontWeight.w400, // Bold 제거
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

        return Bounceable(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarScreen()),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E8EB)),
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191F28),
                        ),
                      ),
                      const SizedBox(height: 16),
                      eventContent,
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 오른쪽 미니 달력
                Expanded(
                  flex: 3,
                  child: IgnorePointer(
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: now,
                      calendarFormat: CalendarFormat.month,
                      headerVisible: false,
                      daysOfWeekHeight: 18,
                      rowHeight: 36,

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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
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
                        weekendStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        weekdayStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
      case "학사":
        return const Color(0xFF82B1FF);
      case "장학":
        return const Color(0xFFFFD180);
      case "취업":
        return const Color(0xFFA5D6A7);
      case "행사":
        return const Color(0xFFCE93D8);

      default:
        return const Color(0xFF3182F6);
    }
  }
}
