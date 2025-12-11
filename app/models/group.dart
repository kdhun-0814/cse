import 'package:flutter/material.dart';

class QnA {
  final String question;
  String? answer;
  final String questionerName;

  QnA({required this.question, required this.questionerName, this.answer});
}

class Group {
  final String id;
  final String title;
  final String content;
  final List<String> hashtags; 
  final DateTime deadline; 
  final int maxMembers; 
  final String? linkUrl; // ★ 변경: 필수 아님 (Nullable)
  
  List<QnA> qnaList; 
  bool isMyGroup; 
  bool isManuallyClosed; 
  bool isLiked;

  Group({
    required this.id,
    required this.title,
    required this.content,
    required this.hashtags,
    required this.deadline,
    required this.maxMembers,
    this.linkUrl, // ★ 변경: required 제거
    this.qnaList = const [],
    this.isMyGroup = false,
    this.isManuallyClosed = false,
    this.isLiked = false,
  });

  bool get isExpired {
    final now = DateTime.now();
    final isDateOver = now.isAfter(deadline.add(const Duration(days: 1))); 
    return isDateOver || isManuallyClosed;
  }
}

// 더미 데이터 수정 (링크 없는 경우 테스트)
final List<Group> dummyGroups = [
  Group(
    id: '1',
    title: '알고리즘 코딩테스트 스터디 구합니다',
    content: '매주 화요일 저녁 7시 모임. 구글 폼으로 신청해주세요.',
    hashtags: ['#스터디', '#코딩', '#알고리즘', '#Java'],
    deadline: DateTime.now().add(const Duration(days: 5)),
    maxMembers: 6,
    linkUrl: 'https://forms.google.com/example',
    qnaList: [
      QnA(question: "비전공자도 가능한가요?", questionerName: "박민수", answer: "네 가능합니다!"),
    ],
    isMyGroup: true,
  ),
  Group(
    id: '2',
    title: '같이 밥 먹을 사람~ (오늘 점심)',
    content: '오픈채팅방으로 들어오세요.',
    hashtags: ['#친목', '#점심'],
    deadline: DateTime.now().subtract(const Duration(days: 1)),
    maxMembers: 4,
    linkUrl: null, // ★ 링크 없음
    isMyGroup: false,
    isLiked: true,
  ),
];