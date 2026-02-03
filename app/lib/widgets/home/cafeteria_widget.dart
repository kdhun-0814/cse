import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/custom_loading_indicator.dart';

class CafeteriaWidget extends StatefulWidget {
  final bool forceShow;

  const CafeteriaWidget({super.key, this.forceShow = false});

  @override
  State<CafeteriaWidget> createState() => _CafeteriaWidgetState();
}

class _CafeteriaWidgetState extends State<CafeteriaWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDate; // NEW
  final List<String> _cafeterias = ["중앙식당", "교문센1층", "교직원식당", "칠암"];

  // 선택된 날짜의 문서 ID (YYYY-MM-DD)
  String get _docId {
    return DateFormat('yyyy-MM-dd').format(_selectedDate); // NEW
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // NEW
    _tabController = TabController(length: _cafeterias.length, vsync: this);
  }

  // NEW: Date Picker
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF3182F6),
            colorScheme: const ColorScheme.light(primary: Color(0xFF3182F6)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.forceShow) {
      // 위젯 관리 화면이 아닐 때는 Firestore에서 데이터 확인 후 표시 여부 결정
      // (단, 데이터가 없어도 "오늘 식단 없음"이라고 보여주는게 나을 수 있음)
      // 여기서는 항상 보여주되 로딩/에러 처리
    }

    return Container(
      // margin 제거 (공지통합검색과 동일)
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          // 헤더 (클릭 시 날짜 변경)
          InkWell(
            onTap: _pickDate,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        color: Color(0xFF3182F6),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "오늘의 학식",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191F28),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        DateFormat(
                          'MM.dd (E)',
                          'ko_KR',
                        ).format(_selectedDate), // NEW
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B95A1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF8B95A1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 탭 바 (식당 선택)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF3182F6),
            unselectedLabelColor: const Color(0xFF8B95A1),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            indicatorColor: const Color(0xFF3182F6),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: _cafeterias.map((e) => Tab(text: e)).toList(),
            dividerColor: Colors.transparent, // 하단 줄 제거
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tabAlignment: TabAlignment.start,
          ),

          const Divider(height: 1, color: Color(0xFFF2F4F6)),

          // 내용 (메뉴 텍스트)
          SizedBox(
            height: 220, // 높이 증가 (오늘의 일정 위젯과 유사하게)
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cafeteria_menus')
                  .doc(_docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoadingIndicator());
                }

                Map<String, dynamic> menus = {};
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  menus = data['menus'] as Map<String, dynamic>? ?? {};
                }

                return TabBarView(
                  controller: _tabController,
                  children: _cafeterias.map((cafeName) {
                    final menuText = menus[cafeName] ?? "식단 정보가 없습니다.";

                    if (menuText == "운영 없음" || menuText == "정보 없음 (Error)") {
                      return Center(
                        child: Text(
                          menuText,
                          style: const TextStyle(color: Color(0xFFB0B8C1)),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        menuText,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          color: const Color(0xFF333D4B),
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
