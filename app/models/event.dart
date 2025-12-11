import 'package:flutter/material.dart';

class Event {
  final String title;
  final String category;
  final Color color;

  Event(this.title, this.category, this.color);
}

// 더미 데이터
final kToday = DateTime.now();
final kEvents = {
  DateTime.utc(kToday.year, kToday.month, kToday.day): [
    Event('수강신청 장바구니 담기', '학사', const Color(0xFF82B1FF)),
    Event('삼성전자 채용 설명회', '취업', const Color(0xFFA5D6A7)),
  ],
  DateTime.utc(kToday.year, kToday.month, kToday.day + 2): [
    Event('국가장학금 신청 마감', '장학', const Color(0xFFFFD180)),
  ],
  DateTime.utc(kToday.year, kToday.month, kToday.day + 5): [
    Event('학과 MT (대성리)', '행사', const Color(0xFFCE93D8)),
  ],
};