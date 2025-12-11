import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String category;
  final DateTime startDate; // ★ 시작일
  final DateTime endDate; // ★ 종료일

  Event({
    required this.id,
    required this.title,
    required this.category,
    required this.startDate,
    required this.endDate,
  });

  Color get color {
    switch (category) {
      case "학사":
        return const Color(0xFF82B1FF);
      case "장학":
        return const Color(0xFFFFD180);
      case "행사":
        return const Color(0xFFCE93D8);
      case "휴일":
        return const Color(0xFFFF8A80);
      case "취업":
        return const Color(0xFFA5D6A7);
      default:
        return const Color(0xFF3182F6);
    }
  }

  // 기간 포맷팅 (UI 표시용)
  String get dateRangeText {
    // 같은 날이면 하루만 표시
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return "${startDate.month}/${startDate.day}";
    }
    // 기간이면 "10/20 ~ 10/24"
    return "${startDate.month}/${startDate.day} ~ ${endDate.month}/${endDate.day}";
  }

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime start = DateTime.now();
    DateTime end = DateTime.now();

    // 1. startDate 필드가 있으면 사용, 없으면 기존 date 필드 사용 (호환성)
    if (data['startDate'] != null) {
      start = (data['startDate'] as Timestamp).toDate();
    } else if (data['date'] != null) {
      start = (data['date'] as Timestamp).toDate(); // 기존 데이터 지원
    }

    // 2. endDate 필드가 있으면 사용, 없으면 시작일과 동일하게 설정 (하루짜리 일정)
    if (data['endDate'] != null) {
      end = (data['endDate'] as Timestamp).toDate();
    } else {
      end = start;
    }

    return Event(
      id: doc.id,
      title: data['title'] ?? '제목 없음',
      category: data['category'] ?? '기타',
      startDate: start,
      endDate: end,
    );
  }
}
