import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QnA {
  final String question;
  String? answer;
  final String questionerName;

  QnA({required this.question, required this.questionerName, this.answer});

  // Map으로 변환 (DB 저장용)
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'questionerName': questionerName,
      'answer': answer,
    };
  }

  // Map에서 객체로 (DB 읽기용)
  factory QnA.fromMap(Map<String, dynamic> map) {
    return QnA(
      question: map['question'] ?? '',
      questionerName: map['questionerName'] ?? '익명',
      answer: map['answer'],
    );
  }
}

class Group {
  final String id;
  final String authorId; // ★ 작성자 UID (DB 저장)
  final String title;
  final String content;
  final List<String> hashtags;
  final DateTime deadline;
  final int maxMembers;
  final String? linkUrl;

  List<QnA> qnaList;
  bool isManuallyClosed;

  // ★ UI용 계산 필드 (DB 저장 X)
  final bool isMyGroup;
  final bool isLiked;
  final bool isOfficial; // ★ 공식(학생회) 글 여부

  Group({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.hashtags,
    required this.deadline,
    required this.maxMembers,
    this.linkUrl,
    this.qnaList = const [],
    this.isManuallyClosed = false,
    this.isMyGroup = false,
    this.isLiked = false,
    this.isOfficial = false, // 기본값 false
  });

  bool get isExpired {
    final now = DateTime.now();
    // 마감일 다음날 0시가 지나면 만료로 처리
    final isDateOver = now.isAfter(deadline.add(const Duration(days: 1)));
    return isDateOver || isManuallyClosed;
  }

  // ★ Firestore -> App
  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;

    // QnA 리스트 변환
    var qnaData = data['qnaList'] as List<dynamic>? ?? [];
    List<QnA> qnas = qnaData.map((e) => QnA.fromMap(e)).toList();

    // 찜 목록 확인 (List<String> likes 필드가 DB에 있다고 가정)
    List<dynamic> likes = data['likes'] ?? [];
    bool liked = currentUser != null && likes.contains(currentUser.uid);

    return Group(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      hashtags: List<String>.from(data['hashtags'] ?? []),
      deadline: (data['deadline'] as Timestamp).toDate(),
      maxMembers: data['maxMembers'] ?? 1,
      linkUrl: data['linkUrl'],
      qnaList: qnas,
      isManuallyClosed: data['isManuallyClosed'] ?? false,

      // 로그인한 유저 ID와 작성자 ID 비교
      isMyGroup: currentUser != null && (data['authorId'] == currentUser.uid),
      isLiked: liked,
      isOfficial: data['isOfficial'] ?? false,
    );
  }
}
