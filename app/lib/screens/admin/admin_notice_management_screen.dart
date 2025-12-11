import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notice.dart';
import '../../services/firestore_service.dart';

class AdminNoticeManagementScreen extends StatefulWidget {
  const AdminNoticeManagementScreen({super.key});

  @override
  State<AdminNoticeManagementScreen> createState() =>
      _AdminNoticeManagementScreenState();
}

class _AdminNoticeManagementScreenState
    extends State<AdminNoticeManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "전체";
  final List<String> _categories = [
    "전체",
    "학사",
    "장학",
    "취업",
    "학과행사",
    "외부행사",
    "공모전",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "제목 검색...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : const Text(
                "공지사항 통합 관리",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "게시 중"),
            Tab(text: "삭제됨"),
          ],
        ),
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.blue,
                      checkmarkColor: Colors.white,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 리스트 뷰
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: _firestoreService.getAdminNotices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allNotices = snapshot.data ?? [];

                // 공통 필터링 로직
                final filtered = allNotices.where((n) {
                  if (_selectedCategory != "전체" &&
                      n.category != _selectedCategory)
                    return false;
                  if (_searchQuery.isNotEmpty &&
                      !n.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ))
                    return false;
                  return true;
                }).toList();

                final liveNotices = filtered
                    .where((n) => !n.isDeleted)
                    .toList();
                final deletedNotices = filtered
                    .where((n) => n.isDeleted)
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNoticeList(liveNotices, isDeletedTab: false),
                    _buildNoticeList(deletedNotices, isDeletedTab: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeList(List<Notice> notices, {required bool isDeletedTab}) {
    if (notices.isEmpty) {
      return const Center(
        child: Text("공지가 없습니다.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notices.length,
      itemBuilder: (context, index) {
        final notice = notices[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E8EB)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              notice.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "${notice.category} | ${notice.date}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (notice.isUrgent == true)
                  const Text(
                    "🚨 긴급 공지",
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                if (notice.isImportant == true)
                  const Text(
                    "⭐ 중요 공지",
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenuAction(value, notice, isDeletedTab),
              itemBuilder: (context) {
                if (isDeletedTab) {
                  return [
                    const PopupMenuItem(value: 'restore', child: Text("복구하기")),
                  ];
                } else {
                  return [
                    const PopupMenuItem(
                      value: 'category',
                      child: Text("카테고리 변경"),
                    ),
                    const PopupMenuItem(
                      value: 'push',
                      child: Text("🔔 푸시 알림 발송"),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text("삭제", style: TextStyle(color: Colors.red)),
                    ),
                  ];
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMenuAction(
    String value,
    Notice notice,
    bool isDeletedTab,
  ) async {
    if (value == 'restore') {
      await _firestoreService.restoreNotice(notice.id);
      if (mounted) _showSnackBar("공지가 복구되었습니다.");
    } else if (value == 'delete') {
      await _firestoreService.deleteNotice(notice.id);
      if (mounted) _showSnackBar("공지가 삭제(보관)되었습니다.");
    } else if (value == 'push') {
      _confirmPush(notice);
    } else if (value == 'category') {
      _showCategoryDialog(notice);
    }
  }

  void _confirmPush(Notice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("푸시 알림 발송"),
        content: Text("'${notice.title}'\n\n이 공지의 알림을 전송하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _firestoreService.requestPushNotification(notice.id);
              _showSnackBar("푸시 알림 요청이 전송되었습니다.");
            },
            child: const Text("전송"),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(Notice notice) {
    final categories = ['학사', '장학', '취업', '학과행사', '외부행사', '공모전'];
    String selected = categories.contains(notice.category)
        ? notice.category
        : categories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("카테고리 변경"),
            content: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              items: categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setDialogState(() => selected = val);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _firestoreService.updateNoticeCategory(notice.id, selected);
                  _showSnackBar("카테고리가 변경되었습니다.");
                },
                child: const Text("변경"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
