import 'package:flutter/material.dart';
import '../../models/group.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends StatefulWidget {
  final String filterType; // 'all', 'my', 'liked'

  const GroupListScreen({super.key, this.filterType = 'all'});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 데이터 필터링
    List<Group> filteredList = dummyGroups.where((g) {
      if (widget.filterType == 'my') return g.isMyGroup;
      if (widget.filterType == 'liked') return g.isLiked;
      return true; 
    }).toList();

    if (filteredList.isEmpty) {
      String emptyMsg = "모집 중인 모임이 없어요.";
      if (widget.filterType == 'my') emptyMsg = "내가 만든 모임이 없어요.";
      if (widget.filterType == 'liked') emptyMsg = "찜한 모임이 없어요.";

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );
    }

    // 순수 리스트 반환 (Scaffold X)
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: filteredList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildGroupCard(filteredList[index]);
      },
    );
  }

  Widget _buildGroupCard(Group group) {
    bool isExpired = group.isExpired;

    return GestureDetector(
      onTap: isExpired ? null : () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GroupDetailScreen(group: group)),
        ).then((_) => _refresh());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Opacity(
          opacity: isExpired ? 0.6 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isExpired ? Colors.grey[200] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 제목 & 찜 버튼
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        group.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF191F28)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          group.isLiked = !group.isLiked;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Icon(
                          group.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: group.isLiked ? const Color(0xFFFF4E4E) : const Color(0xFFB0B8C1),
                          size: 24,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),

                // 2. 해시태그
                Wrap(
                  spacing: 6,
                  children: group.hashtags.map((tag) => Text(
                    tag,
                    style: TextStyle(
                      color: isExpired ? Colors.grey : const Color(0xFF3182F6),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                
                // 3. 정보 (인원, 마감일)
                Row(
                  children: [
                    Icon(Icons.people_rounded, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text("${group.maxMembers}명 모집", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 10, color: Colors.grey[300]),
                    const SizedBox(width: 12),
                    Text(
                      isExpired ? "마감됨" : "D-${group.deadline.difference(DateTime.now()).inDays}",
                      style: TextStyle(
                        color: isExpired ? Colors.grey : const Color(0xFFFF4E4E), 
                        fontWeight: FontWeight.bold, fontSize: 13
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}