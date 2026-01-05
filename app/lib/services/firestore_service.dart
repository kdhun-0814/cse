import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../models/notice.dart';
import '../models/group.dart';
import '../models/event.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ★ 1. 현재 유저의 권한(role) 가져오기
  Future<String> getUserRole() async {
    String uid = _auth.currentUser!.uid;
    DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();

    if (userDoc.exists) {
      return userDoc['role'] ?? 'USER'; // role 필드가 없으면 기본값 USER
    }
    return 'USER';
  }

  // 일정 추가 함수 (관리자용)
  Future<void> addEvent({
    required String title,
    required String category,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _db.collection('events').add({
      'title': title,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'date': Timestamp.fromDate(startDate), // 호환성 위해 추가
    });
  }

  // 일정 수정
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String category,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _db.collection('events').doc(eventId).update({
      'title': title,
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    });
  }

  // 일정 삭제
  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }

  // --- 1. 공지사항 (Notice) ---

  // 공지사항 실시간 스트림 (Rx.combineLatest2 사용)
  Stream<List<Notice>> getNotices() {
    String uid = _auth.currentUser!.uid;

    final noticeStream = _db
        .collection('notices')
        .orderBy('date', descending: true)
        .snapshots();

    final userStream = _db.collection('users').doc(uid).snapshots();

    return Rx.combineLatest2(noticeStream, userStream, (
      QuerySnapshot noticeSnapshot,
      DocumentSnapshot userSnapshot,
    ) {
      final scraps = List<String>.from(
        (userSnapshot.data() as Map<String, dynamic>?)?['scraps'] ?? [],
      );

      return noticeSnapshot.docs
          .map((doc) => Notice.fromFirestore(doc, scraps))
          .where((n) => !n.isDeleted) // 숨김 처리된 공지 제외
          .toList();
    });
  }

  // 관리자용 - 모든 공지 가져오기 (삭제된 것 포함)
  Stream<List<Notice>> getAdminNotices() {
    return _db
        .collection('notices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Notice.fromFirestore(doc, []))
              .toList();
        });
  }

  // 스크랩 토글
  Future<void> toggleNoticeScrap(String noticeId, bool currentStatus) async {
    String uid = _auth.currentUser!.uid;
    DocumentReference userRef = _db.collection('users').doc(uid);

    if (currentStatus) {
      await userRef.update({
        'scraps': FieldValue.arrayRemove([noticeId]),
      });
    } else {
      await userRef.update({
        'scraps': FieldValue.arrayUnion([noticeId]),
      });
    }
  }

  // 공지 읽음 처리 (및 조회수 증가)
  Future<void> markNoticeAsRead(String noticeId) async {
    String uid = _auth.currentUser!.uid;
    DocumentReference userRef = _db.collection('users').doc(uid);
    DocumentReference noticeRef = _db.collection('notices').doc(noticeId);

    // 1. 유저 읽음 기록 추가
    await userRef.update({
      'readNotices': FieldValue.arrayUnion([noticeId]),
    });

    // 2. 공지 조회수 증가 (전체 + 오늘)
    // 매번 읽을 때마다 증가하면 남용될 수 있으므로, readNotices에 없을 때만 증가시키는 게 좋지만
    // 유저 요청 사항(Hot공지)을 위해 일단 방문 시 무조건 증가 또는 일정 쿨타임(여기선 단순화하여 방문시 증가)
    // 다만, 'readNotices' 확인 후 증가시키면 재방문 시 카운트가 안되므로 Hot공지 로직에 불리함.
    // 따라서 무조건 증가시키되, 어뷰징 방지는 별도 고려 필요. 여기선 바로 증가.
    await noticeRef.update({
      'views': FieldValue.increment(1),
      'views_today': FieldValue.increment(1),
    });
  }

  // 카테고리별 스마트 공지 개수 스트림 (마지막 방문 이후 새로 올라온 것)
  Stream<int> getNoticeCount(String category) {
    String uid = _auth.currentUser!.uid;

    // 1. 공지 스트림 (최근 100개만 가져와서 클라이언트 필터링 - 효율성 고려)
    // 혹은 crawled_at 기준으로 쿼리하면 좋지만, last_visit이 동적이므로 쿼리에 넣기 애매함
    // 여기선 분류별 최신순으로 가져와서 비교
    final noticeStream = _db
        .collection('notices')
        .where('category', isEqualTo: category)
        .orderBy('crawled_at', descending: true)
        .limit(50) // 배지에는 50개 이상 표시할 일이 드물므로 제한
        .snapshots();

    // 2. 유저 스트림 (last_visits 필드 확인)
    final userStream = _db.collection('users').doc(uid).snapshots();

    // 3. 두 스트림 결합
    return Rx.combineLatest2(noticeStream, userStream, (
      QuerySnapshot noticeSnapshot,
      DocumentSnapshot userSnapshot,
    ) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final lastVisits =
          userData?['last_visits'] as Map<String, dynamic>? ?? {};

      // 해당 카테고리의 마지막 방문 시간 가져오기
      Timestamp? lastVisitTs = lastVisits[category] as Timestamp?;

      // 방문 기록이 없으면?
      // 정책: "처음이면 모두 새글" vs "처음이면 0개(방문해야 카운트 시작)"
      // 통상적으로 앱 설치 후 첫 진입 시 배지가 너무 많으면 부담스러우므로 0개로 하거나,
      // 혹은 오늘 날짜 기준으로 하거나.
      // 여기선: 방문 기록 없으면 -> 오늘 올라온 것만 카운트 (기존 로직 fallback)
      DateTime cutoffTime;
      if (lastVisitTs != null) {
        cutoffTime = lastVisitTs.toDate();
      } else {
        final now = DateTime.now();
        cutoffTime = DateTime(now.year, now.month, now.day);
      }

      int newCount = 0;
      for (var doc in noticeSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // crawled_at이 없으면 date(문자열)로 추정하거나 제외
        // 크롤러가 crawled_at을 넣어주므로 믿고 씀. 없으면 패스.
        if (data['crawled_at'] is Timestamp) {
          DateTime crawledAt = (data['crawled_at'] as Timestamp).toDate();
          if (crawledAt.isAfter(cutoffTime)) {
            newCount++;
          }
        }
      }
      return newCount;
    });
  }

  // 유저 방문 기록 업데이트
  Future<void> updateLastVisited(String category) async {
    String uid = _auth.currentUser!.uid;
    // last_visits 맵의 해당 카테고리 필드를 현재 시간으로 업데이트
    await _db.collection('users').doc(uid).set({
      'last_visits': {category: FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
  }

  // 관리자 기능: 중요 공지 설정
  Future<void> setNoticeImportant(String noticeId, bool isImportant) async {
    await _db.collection('notices').doc(noticeId).update({
      'is_important': isImportant,
    });
  }

  // 관리자 기능: 긴급 공지 설정 (수동)
  Future<void> setNoticeUrgent(String noticeId, bool isUrgent) async {
    await _db.collection('notices').doc(noticeId).update({
      'is_urgent': isUrgent,
      'is_manual': true, // 수동 설정 여부 표시
    });
  }

  // 관리자 기능: 공지 작성 (외부행사 포함, 일반/긴급/중요 설정 가능)
  Future<void> createNotice({
    required String title,
    required String content,
    required String category,
    String? link,
    required List<String> imageUrls,
    bool isImportant = false,
    bool isUrgent = false,
  }) async {
    final now = DateTime.now();
    final dateStr =
        "${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}";

    await _db.collection('notices').add({
      'category': category,
      'title': title,
      'content': content,
      'link': link ?? '',
      'date': dateStr,
      'imageUrls': imageUrls,
      'author': '관리자',
      'views': 0,
      'views_today': 0,
      'is_manual': true,
      'created_at': FieldValue.serverTimestamp(),
      'is_important': isImportant,
      'is_urgent': isUrgent,
      'files': [],
    });
  }

  // 관리자 기능: 공지 삭제 (Soft Delete)
  Future<void> deleteNotice(String noticeId) async {
    await _db.collection('notices').doc(noticeId).update({'is_deleted': true});
  }

  // 관리자 기능: 공지 복구
  Future<void> restoreNotice(String noticeId) async {
    await _db.collection('notices').doc(noticeId).update({'is_deleted': false});
  }

  // 관리자 기능: 공지 카테고리 변경 (앱 전용)
  Future<void> updateNoticeCategory(String noticeId, String newCategory) async {
    await _db.collection('notices').doc(noticeId).update({
      'category': newCategory,
    });
  }

  // 관리자 기능: 푸시 알림 요청
  Future<void> requestPushNotification(String noticeId) async {
    // 실제 발송은 서버(Cloud Functions/Python)에서 'push_requested' 필드를 감지하여 처리한다고 가정
    await _db.collection('notices').doc(noticeId).update({
      'push_requested': true,
      'push_requested_at': FieldValue.serverTimestamp(),
    });
  }

  // 유저 설정: 전체 푸시 알림 토글
  Future<void> togglePushSetting(bool isEnabled) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).set({
      'isPushEnabled': isEnabled,
    }, SetOptions(merge: true));
  }

  // 유저 설정: 카테고리별 푸시 알림 토글
  Future<void> toggleCategoryPushSetting(
    String category,
    bool isEnabled,
  ) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).set({
      'push_settings': {category: isEnabled},
    }, SetOptions(merge: true));
  }

  // 카테고리별 푸시 설정 스트림
  Stream<bool> getCategoryPushSetting(String category) {
    String uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return true; // 기본값 On
      final data = snapshot.data() as Map<String, dynamic>;

      // 전체 알림이 꺼져있으면 무조건 false (선택 사항, 여기선 독립적으로 처리하거나 UI에서 처리)
      // 여기선 개별 설정값만 반환
      final settings = data['push_settings'] as Map<String, dynamic>?;
      if (settings != null && settings.containsKey(category)) {
        return settings[category] as bool;
      }
      return true; // 기본값 true
    });
  }

  // --- 2. 모임 (Group) ---

  // 모임 생성
  Future<void> createGroup({
    required String title,
    required String content,
    required List<String> hashtags,
    required DateTime deadline,
    required int maxMembers,
    String? linkUrl,
    bool isOfficial = false,
  }) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('groups').add({
      'authorId': uid,
      'title': title,
      'content': content,
      'hashtags': hashtags,
      'deadline': Timestamp.fromDate(deadline),
      'maxMembers': maxMembers,
      'linkUrl': linkUrl,
      'qnaList': [], // ★ comments -> qnaList
      'likes': [],
      'isManuallyClosed': false,
      'isOfficial': isOfficial,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 모임 수정
  Future<void> updateGroup({
    required String groupId,
    required String title,
    required String content,
    required List<String> hashtags,
    required DateTime deadline,
    required int maxMembers,
    String? linkUrl,
    bool isOfficial = false,
  }) async {
    await _db.collection('groups').doc(groupId).update({
      'title': title,
      'content': content,
      'hashtags': hashtags,
      'deadline': Timestamp.fromDate(deadline),
      'maxMembers': maxMembers,
      'linkUrl': linkUrl,
      'isOfficial': isOfficial,
    });
  }

  // 모임 목록 스트림
  Stream<List<Group>> getGroups(String filterType) {
    Query query = _db
        .collection('groups')
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      List<Group> allGroups = snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .toList();

      if (filterType == 'my') {
        return allGroups.where((g) => g.isMyGroup).toList();
      } else if (filterType == 'liked') {
        return allGroups.where((g) => g.isLiked).toList();
      }
      return allGroups;
    });
  }

  // 특정 모임 스트림 (상세화면용)
  Stream<Group> getGroupStream(String groupId) {
    return _db.collection('groups').doc(groupId).snapshots().map((doc) {
      return Group.fromFirestore(doc);
    });
  }

  // 모임 찜하기 토글
  Future<void> toggleGroupLike(String groupId, bool currentStatus) async {
    String uid = _auth.currentUser!.uid;
    DocumentReference groupRef = _db.collection('groups').doc(groupId);

    if (currentStatus) {
      await groupRef.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await groupRef.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // 모임 마감하기
  Future<void> closeGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).update({
      'isManuallyClosed': true,
    });
  }

  // 모임 삭제하기
  Future<void> deleteGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).delete();
  }

  // ★ 질문/답변 등록 (Advanced QnA)
  Future<void> addQnA({
    required String groupId,
    required String content,
    required bool isAnonymous,
    String? replyToId,
  }) async {
    String uid = _auth.currentUser!.uid;
    DocumentReference groupRef = _db.collection('groups').doc(groupId);

    // 트랜잭션으로 처리하여 익명 ID 충돌 방지 및 안전한 추가
    await _db.runTransaction((transaction) async {
      DocumentSnapshot groupSnapshot = await transaction.get(groupRef);
      if (!groupSnapshot.exists) return;

      Map<String, dynamic> data = groupSnapshot.data() as Map<String, dynamic>;
      List<dynamic> qnaListDynamic = data['qnaList'] ?? [];
      List<QnAItem> qnaList =
          qnaListDynamic.map((e) => QnAItem.fromMap(e)).toList();

      // 익명 ID 로직
      int? anonymousId;
      if (isAnonymous) {
        // 이미 익명으로 작성한 적이 있는지 확인
        try {
          // 같은 유저가 쓴 익명 글 찾기
          var myAnonymousPost = qnaList.firstWhere(
            (q) => q.userId == uid && q.isAnonymous && q.anonymousId != null,
          );
          anonymousId = myAnonymousPost.anonymousId;
        } catch (e) {
          // 없으면 새로운 번호 부여
          // 기존 익명 번호들의 최댓값 찾기
          int maxId = 0;
          for (var q in qnaList) {
            if (q.anonymousId != null && q.anonymousId! > maxId) {
              maxId = q.anonymousId!;
            }
          }
          anonymousId = maxId + 1;
        }
      }

      // 유저 이름 가져오기
      DocumentSnapshot userDoc = await transaction
          .get(_db.collection('users').doc(uid));
      String userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? '익명';

      // 새 항목 생성
      QnAItem newItem = QnAItem(
        id: const Uuid().v4(), // pubspec.yaml에 uuid 패키지 필요 (없을 시 string interpolation으로 대체)
        userId: uid,
        userName: userName,
        content: content,
        createdAt: DateTime.now(),
        isAnonymous: isAnonymous,
        anonymousId: anonymousId,
        replyToId: replyToId,
      );

      // 배열에 추가
      transaction.update(groupRef, {
        'qnaList': FieldValue.arrayUnion([newItem.toMap()]),
      });
    });
  }

  // ★ QnA 수정
  Future<void> updateQnA(String groupId, String qnaId, String newContent) async {
    DocumentReference groupRef = _db.collection('groups').doc(groupId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot groupSnapshot = await transaction.get(groupRef);
      if (!groupSnapshot.exists) return;

      Map<String, dynamic> data = groupSnapshot.data() as Map<String, dynamic>;
      List<dynamic> qnaListDynamic = data['qnaList'] ?? [];
      
      // 전체 리스트를 새로 만들어서 교체해야 함 (배열 내 특정 객체 수정 불가)
      List<Map<String, dynamic>> updatedList = [];
      
      for (var item in qnaListDynamic) {
        if (item['id'] == qnaId) {
          item['content'] = newContent;
          item['isEdited'] = true;
        }
        updatedList.add(item);
      }

      transaction.update(groupRef, {'qnaList': updatedList});
    });
  }

  // ★ QnA 삭제 (Soft Delete)
  Future<void> deleteQnA(String groupId, String qnaId) async {
    DocumentReference groupRef = _db.collection('groups').doc(groupId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot groupSnapshot = await transaction.get(groupRef);
      if (!groupSnapshot.exists) return;

      Map<String, dynamic> data = groupSnapshot.data() as Map<String, dynamic>;
      List<dynamic> qnaListDynamic = data['qnaList'] ?? [];
      
      List<Map<String, dynamic>> updatedList = [];
      
      for (var item in qnaListDynamic) {
        if (item['id'] == qnaId) {
          item['isDeleted'] = true;
          // 내용은 유지 or "삭제된 메시지"로 변경? 요구사항에는 없으나 보통 내용도 가림.
          // 여기선 isDeleted 플래그만 세우고 UI에서 처리
        }
        updatedList.add(item);
      }

      transaction.update(groupRef, {'qnaList': updatedList});
    });
  }

  // --- 3. 학사 일정 (Event) ---

  // 모든 일정 가져오기
  Stream<List<Event>> getEvents() {
    return _db.collection('events').orderBy('startDate').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }
  // --- 4. 홈 위젯 관리 ---

  // 위젯 설정 저장
  Future<void> saveHomeWidgetConfig(
    List<Map<String, dynamic>> widgetConfigs,
  ) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).set({
      'home_widget_config': widgetConfigs,
    }, SetOptions(merge: true));
  }

  // 위젯 설정 불러오기 (Stream)
  Stream<List<Map<String, dynamic>>> getHomeWidgetConfig() {
    String uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('home_widget_config')) {
          return List<Map<String, dynamic>>.from(data['home_widget_config']);
        }
      }
      return []; // 설정이 없으면 빈 리스트 반환
    });
  }
}
