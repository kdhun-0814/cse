import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/firestore_service.dart';
import 'notice_detail_screen.dart';
import 'dart:async'; // StreamSubscription

class ScrapScreen extends StatefulWidget {
  const ScrapScreen({super.key});

  @override
  State<ScrapScreen> createState() => _ScrapScreenState();
}

class _ScrapScreenState extends State<ScrapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController(); // ★ 추가

  String _selectedCategory = "전체";
  // Updated category list as requested
  final List<String> _categories = ["전체", "학사", "장학", "취업", "공모전", "학과행사", "외부행사"];
  bool _isScrolled = false;

  String _searchQuery = ""; // 검색어 변수 추가

  // 데이터 관리용
  late StreamSubscription<List<Notice>> _subscription;
  List<Notice> _displayedNotices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 스트림 구독 시작
    _subscription = _firestoreService.getNotices().listen((allNotices) {
      _processUpdates(allNotices);
    });

    // 스크롤 리스너 추가 (구분선 로직, 깜빡임 방지 적용)
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
    _subscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // 데이터 갱신 및 애니메이션 처리 로직
  void _processUpdates(List<Notice> allNotices) {
    // 1. 현재 조건(스크랩+카테고리+검색어)에 맞는 새 리스트 생성
    List<Notice> newFiltered = allNotices.where((n) {
      if (!n.isScraped) return false;
      
      // Category Filtering
      if (_selectedCategory != "전체") {
        // exact category match
        if (n.category != _selectedCategory) return false; 
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!n.title.toLowerCase().contains(query) &&
            !n.content.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    // 2. 초기 로딩인 경우
    if (_isLoading) {
      if (mounted) {
        setState(() {
          _displayedNotices = newFiltered;
          _isLoading = false;
        });
      }
      return;
    }

    // 3. Diff 알고리즘 (삭제 위주 처리)
    // Removed Items (Reverse order to maintain indices)
    for (int i = _displayedNotices.length - 1; i >= 0; i--) {
      final oldItem = _displayedNotices[i];
      // 새 리스트에 없는 항목 찾기 (ID 기준)
      final exists = newFiltered.any((n) => n.id == oldItem.id);

      if (!exists) {
        final removedItem = _displayedNotices.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) =>
              _buildScrapItem(removedItem, animation: animation),
          duration: const Duration(milliseconds: 500),
        );
      }
    }

    // Added Items
    for (int i = 0; i < newFiltered.length; i++) {
      final newItem = newFiltered[i];
      // 현재 리스트에 없는 항목 찾기
      final existsIndex = _displayedNotices.indexWhere(
        (n) => n.id == newItem.id,
      );

      if (existsIndex == -1) {
        // 실제로는 정렬 순서를 고려해야 하지만, 여기서는 단순 추가로 처리하거나
        // 간단히 인덱스를 맞춰서 insert.
        // * Firestore가 날짜순 정렬이므로 newFiltered 순서대로 insert하는게 맞음
        // 하지만 이미 삭제가 처리되었으므로, 중간 삽입 로직이 필요.
        // 현재는 단순화를 위해 "존재하지 않으면 삽입"을 수행하되,
        // 애니메이션이 복잡해질 수 있으므로, 리스트 전체 갱신(setState)보다는
        // 1개씩 사라지는 애니메이션(Unscrap)이 핵심이므로 삭제 애니메이션만 보장하고,
        // 추가/재정렬은 setState로 맞추는 전략도 가능.
        // 여기서는 안전하게 insert 0 (최신순 가정) 혹은 i 에 삽입
        _displayedNotices.insert(i, newItem);
        _listKey.currentState?.insertItem(i);
      } else {
        // 이미 존재하면 데이터 업데이트 (내용 변경 등)
        _displayedNotices[existsIndex] = newItem;
      }
    }
  }

  // 카테고리 변경 시 처리
  void _onCategoryChanged(String newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      // 카테고리 변경 시에는 애니메이션 없이 즉시 리로딩 (UX상 빠릿하게)
      _isLoading = true; // 플래그 리셋하여 _processUpdates에서 즉시 반영하도록 유도
    });
    // 현재 스트림의 마지막 데이터를 다시 받아오거나, 스트림이 BehaviorSubject가 아니므로
    // _firestoreService.getNotices()를 다시 호출하기보단,
    // 현재는 스트림 리스너가 계속 돌고 있으므로,
    // 기존 캐시된 전체 데이터를 저장해두고 필터링만 다시 하는게 효율적.
    // 하지만 구조상 스트림에서 전체 데이터를 안들고 있으므로,
    // 간단히 구독을 잠시 끊고 다시 연결하거나, _processUpdates 를 강제 호출해야 함.
    // 여기서는 간단히 리스트 초기화 후 스트림 재구독이 가장 깔끔.

    _subscription.cancel();
    _displayedNotices.clear(); // 화면 클리어
    _subscription = _firestoreService.getNotices().listen((allNotices) {
      _processUpdates(allNotices);
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "학사":
        return const Color(0xFF90CAF9);
      case "장학":
        return const Color(0xFFFFCC80);
      case "취업":
        return const Color(0xFFA5D6A7);
      case "학과행사":
        return const Color(0xFFCE93D8);
      case "외부행사":
        return const Color(0xFF9E9E9E);
      case "공모전":
        return const Color(0xFFFFEE58);
      case "광고":
        return const Color(0xFFB0BEC5);
      default:
        return const Color(0xFF3182F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text(
          '나의 스크랩',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF191F28),
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF2F4F6),
      ),
      body: Column(
        children: [
          // 상단 필터바 & 검색바
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              border: _isScrolled
                  ? const Border(
                      bottom: BorderSide(color: Color(0xFFE5E8EB), width: 1),
                    )
                  : null,
            ),
            child: Column(
              children: [
                // 검색 바
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E8EB)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        // 검색어 변경 시 리스트 갱신 유도
                        _subscription.cancel();
                        _displayedNotices.clear();
                        _isLoading = true;
                        _subscription = _firestoreService.getNotices().listen((
                          allNotices,
                        ) {
                          _processUpdates(allNotices);
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "보관함 검색",
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF8B95A1),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                // 카테고리 칩
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            _onCategoryChanged(category);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF3182F6),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4E5968),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : const Color(0xFFE5E8EB),
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ★ 리스트 (AnimatedList)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedNotices.isEmpty
                ? _buildEmptyView()
                : AnimatedList(
                    controller: _scrollController, // ★ 컨트롤러 연결
                    key: _listKey,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    initialItemCount: _displayedNotices.length,
                    itemBuilder: (context, index, animation) {
                      // 인덱스 안전장치 (삭제 도중 호출될 수 있음)
                      if (index >= _displayedNotices.length) {
                        return const SizedBox();
                      }
                      return _buildScrapItem(
                        _displayedNotices[index],
                        animation: animation,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.bookmark_outline_rounded,
            size: 60,
            color: Color(0xFFD1D6DB),
          ),
          SizedBox(height: 16),
          Text(
            "스크랩 한 공지가 없어요",
            style: TextStyle(fontSize: 15, color: Color(0xFF8B95A1)),
          ),
        ],
      ),
    );
  }

  Widget _buildScrapItem(Notice notice, {Animation<double>? animation}) {
    final color = _getCategoryColor(notice.category);

    return FadeTransition(
      opacity: animation != null
          ? CurvedAnimation(parent: animation, curve: Curves.easeInOut)
          : const AlwaysStoppedAnimation(1.0),
      child: ScaleTransition(
        scale: animation != null
            ? CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)
            : const AlwaysStoppedAnimation(1.0),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoticeDetailScreen(notice: notice),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E8EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notice.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notice.date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B95A1),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          _firestoreService.toggleNoticeScrap(
                            notice.id,
                            notice.isScraped,
                          );
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !notice.isScraped
                                    ? "스크랩 보관함에 저장되었어요."
                                    : "스크랩이 해제되었어요.",
                              ),
                              duration: const Duration(milliseconds: 1000),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Icon(
                          notice.isScraped
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: notice.isScraped
                              ? const Color(0xFFFFD180)
                              : const Color(0xFFD1D6DB),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notice.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191F28),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
