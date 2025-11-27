// lib/group_liked_screen.dart
import 'package:flutter/material.dart';
import 'group_card.dart';

class GroupLikedScreen extends StatelessWidget {
  const GroupLikedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        title: const Text('찜한 목록', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          GroupCard(
            title: '같이 밥 먹을 사람~ (오늘 점심)',
            tags: ['#친목', '#점심'],
            currentMember: 4,
            deadline: '마감됨',
            isRecruiting: false,
            isLiked: true, // 하트가 눌려있음
          ),
          // 추가 데이터를 원하면 여기에 더 GroupCard를 넣으면 됩니다.
        ],
      ),
    );
  }
}