import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';
import '../services/firestore_service.dart';
import 'notice_detail_screen.dart';
import '../widgets/common/custom_loading_indicator.dart';
import '../utils/toast_utils.dart';

class NoticeSearchScreen extends StatefulWidget {
  const NoticeSearchScreen({super.key});

  @override
  State<NoticeSearchScreen> createState() => _NoticeSearchScreenState();
}

class _NoticeSearchScreenState extends State<NoticeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = "";
  List<Notice> _allNotices = [];
  List<Notice> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _fetchAllNotices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Fetch all notices once (assuming reasonable dataset for client-side search)
  // Optimization: For very large datasets, use Firestore 'array-contains' or Algolia
  Future<void> _fetchAllNotices() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notices')
          .orderBy('date', descending: true)
          .limit(300) // Limit to recent 300 for performance
          .get();

      setState(() {
        _allNotices = snapshot.docs
            .map((doc) => Notice.fromFirestore(doc, []))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.show(context, "데이터를 불러오는데 실패했습니다.", isError: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _allNotices.where((notice) {
          final titleMatch = notice.title.toLowerCase().contains(
            query.toLowerCase(),
          );
          return titleMatch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: "제목 또는 내용으로 검색해보세요",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator())
          : _query.isEmpty
          ? _buildEmptyState()
          : _searchResults.isEmpty
          ? _buildNoResultState()
          : _buildResultList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            "궁금한 공지사항을 검색해보세요",
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            "'$_query'에 대한 검색 결과가 없어요",
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _searchResults.length,
      separatorBuilder: (ctx, idx) =>
          const Divider(height: 1, color: Color(0xFFF2F4F6)),
      itemBuilder: (context, index) {
        final notice = _searchResults[index];
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoticeDetailScreen(notice: notice),
              ),
            );
          },
          title: Text(
            notice.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          subtitle: Row(
            children: [
              Text(
                notice.category,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3182F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                notice.date,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        );
      },
    );
  }
}
