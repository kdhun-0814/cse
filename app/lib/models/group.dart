import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QnAItem {
  final String id; // UUID
  final String userId; // 실제 작성자 UID
  final String userName; // 실제 작성자 이름
  final String content;
  final DateTime createdAt;
  final bool isAnonymous;
  final int? anonymousId; // 익명 번호 (익명1, 익명2...)
  final String? replyToId; // 부모 질문 ID (null이면 새 질문)
  final bool isDeleted;
  final bool isEdited;

  QnAItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
    this.isAnonymous = false,
    this.anonymousId,
    this.replyToId,
    this.isDeleted = false,
    this.isEdited = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAnonymous': isAnonymous,
      'anonymousId': anonymousId,
      'replyToId': replyToId,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
    };
  }

  factory QnAItem.fromMap(Map<String, dynamic> map) {
    return QnAItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '익명',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAnonymous: map['isAnonymous'] ?? false,
      anonymousId: map['anonymousId'],
      replyToId: map['replyToId'],
      isDeleted: map['isDeleted'] ?? false,
      isEdited: map['isEdited'] ?? false,
    );
  }
}

class Group {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final List<String> hashtags;
  final DateTime deadline;
  final int maxMembers;
  final String? linkUrl;

  List<QnAItem> qnaList; // ★ Advanced QnA
  bool isManuallyClosed;

  final bool isMyGroup;
  final bool isLiked;
  final int likeCount;
  final bool isOfficial;

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
    this.likeCount = 0,
    this.isOfficial = false,
  });

  bool get isExpired {
    final now = DateTime.now();
    final isDateOver = now.isAfter(deadline.add(const Duration(days: 1)));
    return isDateOver || isManuallyClosed;
  }

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;

    // QnA 리스트 변환 (DB 필드명 'qnaList'로 복귀 or 'comments' 유지? -> 'qnaList'로 변경)
    // 기존 데이터 'comments'가 있다면 마이그레이션 필요하지만, 개발 단계이므로 'qnaList' 사용.
    // 만약 이전 'comments'를 살리고 싶다면 아래에서 체크해야 함.
    var qnaData = data['qnaList'] as List<dynamic>? ?? [];
    List<QnAItem> loadedQnas =
        qnaData.map((e) => QnAItem.fromMap(e)).toList();

    // 찜 목록 확인
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
      qnaList: loadedQnas,
      isManuallyClosed: data['isManuallyClosed'] ?? false,
      isMyGroup: currentUser != null && (data['authorId'] == currentUser.uid),
      isLiked: liked,
      likeCount: likes.length,
      isOfficial: data['isOfficial'] ?? false,
    );
  }
}
