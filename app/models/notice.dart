import 'package:flutter/material.dart';

class Notice {
  final String id;
  final String category; // 학사, 장학, 취업 등
  final String title;
  final String date;
  final String content; // 본문 내용
  final List<String> imageUrls; // 이미지 링크 리스트
  bool isScraped; // 스크랩 여부 (변경 가능)

  Notice({
    required this.id,
    required this.category,
    required this.title,
    required this.date,
    required this.content,
    this.imageUrls = const [],
    this.isScraped = false,
  });
}

// --- 테스트용 더미 데이터 (전역 변수처럼 사용) ---
// 실제로는 나중에 서버(Python/Firebase)에서 받아올 데이터입니다.
final List<Notice> dummyNotices = [
  Notice(
    id: '1',
    category: '학사',
    title: '2025학년도 1학기 수강신청 안내 (필독)',
    date: '2025.11.23',
    content: '2025학년도 1학기 수강신청 일정을 다음과 같이 안내합니다.\n\n1. 장바구니 기간: 11월 20일 ~ 22일\n2. 본 수강신청: 11월 25일 ~ 27일\n\n학년별 지정 일자가 다르니 반드시 첨부파일을 확인해주시기 바랍니다. 서버 시간을 기준으로 진행됩니다.',
    imageUrls: ['https://picsum.photos/id/1/400/300', 'https://picsum.photos/id/2/400/300'], // 랜덤 이미지
    isScraped: false,
  ),
  Notice(
    id: '2',
    category: '장학',
    title: '국가장학금 1차 신청 마감 임박',
    date: '2025.11.22',
    content: '한국장학재단 국가장학금 1차 신청이 3일 뒤 마감됩니다.\n가구원 동의가 완료되어야 심사가 진행되니 유의 바랍니다.',
    isScraped: true, // 테스트용으로 미리 스크랩 해둠
  ),
  Notice(
    id: '3',
    category: '행사',
    title: '신입생 환영회(OT) 및 새내기 배움터 참여 조사',
    date: '2025.11.21',
    content: '신입생 여러분 환영합니다! \n학과 학생회에서 주최하는 새내기 배움터 참여 인원을 조사합니다.\n구글 폼을 통해 제출해주세요.',
    isScraped: false,
  ),
  Notice(
    id: '4',
    category: '취업',
    title: '삼성전자 하반기 공채 상담회 (학생회관)',
    date: '2025.11.20',
    content: '삼성전자 DX부문 채용 상담회가 학생회관 2층 로비에서 진행됩니다.\n현직 선배님들의 멘토링이 있을 예정이니 많은 참여 바랍니다.',
    imageUrls: ['https://picsum.photos/id/3/400/300'],
    isScraped: false,
  ),
  Notice(
    id: '5',
    category: '긴급공지',
    title: '서버 점검으로 인한 포털 접속 불가 안내',
    date: '2025.11.19',
    content: '금일 밤 10시부터 새벽 2시까지 정기 서버 점검이 있습니다.',
    isScraped: false,
  ),
];