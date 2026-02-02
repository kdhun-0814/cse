import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rxdart/rxdart.dart';
import '../models/notice.dart';
import '../models/group.dart';
import '../models/event.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 학번으로 유저 데이터 찾기 (로그인 최적화용)
  Future<Map<String, dynamic>?> getUserDataByStudentId(String studentId) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print("Error finding user data by student ID: $e");
      return null;
    }
  }

  // 학번으로 이메일 찾기 (구형 - 유지)
  Future<String?> getEmailByStudentId(String studentId) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email'] as String?;
      }
      return null;
    } catch (e) {
      print("Error finding email by student ID: $e");
      return null;
    }
  }

  // 학번 중복 확인
  Future<bool> isStudentIdTaken(String studentId) async {
    final query = await _db
        .collection('users')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // ★ 1. 현재 유저의 권한(role) 가져오기
  Future<String> getUserRole() async {
    String uid = _auth.currentUser!.uid;
    DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();

    if (userDoc.exists) {
      return userDoc['role'] ?? 'USER'; // role 필드가 없으면 기본값 USER
    }
    return 'USER';
  }

  // ★ 관리자용: 대기 중인 모든 유저 일괄 승인
  Future<int> approveAllPendingUsers() async {
    // 1. 대기 중인 유저 쿼리
    final snapshot = await _db
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .get();

    if (snapshot.docs.isEmpty) return 0;

    // 2. 일괄 업데이트 (Batch)
    WriteBatch batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return snapshot.docs.length; // 처리된 수 반환
  }

  // ★ 회원가입 토큰 검증
  Future<bool> verifySignupToken(String inputToken) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('system_config')
          .doc('signup')
          .get();

      if (!doc.exists) return true; // 설정이 없으면 검증 없이 통과 (또는 false로 차단 가능)

      final data = doc.data() as Map<String, dynamic>;
      final String? validToken = data['token'];

      if (validToken == null || validToken.isEmpty) return true; // 토큰 미설정 시 통과

      return inputToken.trim() == validToken;
    } catch (e) {
      print("Error verifying signup token: $e");
      return false; // 에러 시 안전하게 차단
    }
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

  // 공지사항 실시간 스트림 (Rx.combineLatest2 사용) -> Future 기반 페이지네이션으로 변경 예정
  // 기존 코드 유지를 위해 남겨두지만, 메인 목록은 아래 getNoticesPaginated 사용 권장
  Stream<List<Notice>> getNotices() {
    String uid = _auth.currentUser!.uid;

    final noticeStream = _db
        .collection('notices')
        .orderBy('date', descending: true)
        .limit(100)
        .snapshots();

    final userStream = _db.collection('users').doc(uid).snapshots();

    return Rx.combineLatest2(noticeStream, userStream, (
      QuerySnapshot noticeSnapshot,
      DocumentSnapshot userSnapshot,
    ) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final scraps = List<String>.from(userData?['scraps'] ?? []);
      final readNotices = List<String>.from(userData?['readNotices'] ?? []);

      return noticeSnapshot.docs
          .map((doc) => Notice.fromFirestore(doc, scraps, readNotices))
          .where((n) => !n.isDeleted) // 숨김 처리된 공지 제외
          .toList();
    });
  }

  // ★ 페이지네이션 지원 공지사항 가져오기 (Future)
  Future<List<Notice>> fetchNotices({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    bool isUrgentOnly = false,
    bool isImportantOnly = false,
  }) async {
    String uid = _auth.currentUser!.uid;

    Query query = _db.collection('notices');

    // 필터링 적용
    if (isUrgentOnly) {
      query = query.where('is_urgent', isEqualTo: true);
    } else if (isImportantOnly) {
      query = query.where('is_important', isEqualTo: true);
    } else if (category != null && category != '전체') {
      query = query.where('category', isEqualTo: category);
    }

    // 정렬 & Limit
    query = query.orderBy('crawled_at', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final noticeSnapshot = await query.get();

    // 유저 정보는 한 번만 가져오거나 캐시된 것 사용 (여기서는 매번 최신 상태 확인을 위해 get)
    // 최적화를 위해선 유저 정보를 파라미터로 받거나 별도 관리 가능
    DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final scraps = List<String>.from(userData?['scraps'] ?? []);
    final readNotices = List<String>.from(userData?['readNotices'] ?? []);

    return noticeSnapshot.docs
        .map((doc) => Notice.fromFirestore(doc, scraps, readNotices))
        .where((n) => !n.isDeleted)
        .toList();
  }

  // ★ 알림 설정 토글 (Firestore에 저장)
  Future<void> toggleNotificationSetting(String key, bool isEnabled) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).set({
      'notification_settings': {key: isEnabled},
    }, SetOptions(merge: true));
  }

  // 관리자용 - 모든 공지 가져오기 (삭제된 것 포함)
  Stream<List<Notice>> getAdminNotices() {
    return _db
        .collection('notices')
        .orderBy('date', descending: true)
        .limit(100) // 최근 100개만
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Notice.fromFirestore(doc, []))
              .toList();
        });
  }

  // 알림 센터용 - 긴급/중요 공지 가져오기
  Stream<List<Notice>> getUrgentNotices() {
    return _db
        .collection('notices')
        .where('is_urgent', isEqualTo: true) // 긴급 공지 우선
        .orderBy('date', descending: true)
        .limit(50) // 최근 50개만
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Notice.fromFirestore(doc, []))
              .toList();
        });
  }

  // ... (중략) ...

  // 전체 공지 가져오기 (알림센터용: 필터링 & 정렬 적용)
  Stream<List<Notice>> getGlobalRecentNotices() {
    String uid = _auth.currentUser!.uid;

    final noticeStream = _db
        .collection('notices')
        .orderBy('crawled_at', descending: true)
        .limit(30) // ★ 100 -> 30으로 최적화 (초기 로딩 속도 개선)
        .snapshots();

    final userStream = _db.collection('users').doc(uid).snapshots();

    return Rx.combineLatest2(noticeStream, userStream, (
      QuerySnapshot noticeSnapshot,
      DocumentSnapshot userSnapshot,
    ) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final readNotices = List<String>.from(userData?['readNotices'] ?? []);
      final scraps = List<String>.from(userData?['scraps'] ?? []);

      // ★ 설정된 필터 가져오기 (기본값 true)
      final settings =
          userData?['notification_settings'] as Map<String, dynamic>?;

      bool isVisible(Notice n) {
        // 1. 긴급/중요 공지의 표시 여부 확인
        if (n.isUrgent == true) {
          return settings?['urgent'] ?? true;
        }
        if (n.isImportant == true) {
          return settings?['important'] ?? true;
        }

        // 2. 일반 카테고리 공지 표시 여부 확인
        // 카테고리 이름이 정확히 일치해야 함 (예: '학사', '장학' 등)
        return settings?[n.category] ?? true;
      }

      // 1. 객체 변환 및 필터링
      List<Notice> notices = noticeSnapshot.docs
          .map((doc) => Notice.fromFirestore(doc, scraps, readNotices))
          .where((n) => !n.isDeleted && isVisible(n)) // 삭제된 것 제외 + 사용자 설정 필터링
          .toList();

      // 2. 정렬 (긴급 > 중요 > 일반(날짜순))
      notices.sort((a, b) {
        // 긴급 우선
        if ((a.isUrgent ?? false) != (b.isUrgent ?? false)) {
          return (a.isUrgent ?? false) ? -1 : 1;
        }
        // 중요 차선
        if ((a.isImportant ?? false) != (b.isImportant ?? false)) {
          return (a.isImportant ?? false) ? -1 : 1;
        }
        // 기본은 날짜(크롤링 시간 or 작성 시간) 내림차순
        // Firestore 쿼리에서 이미 crawled_at DESC로 가져왔으므로,
        // 긴급/중요 아닌 것들은 순서 유지됨.
        // 다만 '긴급'끼리나 '중요'끼리의 정렬이 필요하다면 여기서 date 비교 추가 가능
        return 0; // 기존 순서 유지
      });

      return notices;
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

    // 2. 공지 조회수 증가
    await noticeRef.update({
      'views': FieldValue.increment(1),
      'views_today': FieldValue.increment(1),
    });
  }

  // 전체 공지(최근 100개) 일괄 읽음 처리
  Future<void> markAllGlobalNoticesAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _db
          .collection('notices')
          .orderBy('crawled_at', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) return;

      final noticeIds = snapshot.docs.map((doc) => doc.id).toList();

      try {
        await _db.collection('users').doc(user.uid).update({
          'readNotices': FieldValue.arrayUnion(noticeIds),
        });
      } catch (e) {
        // 문서가 없거나 업데이트 실패 시 생성/병합 시도
        await _db.collection('users').doc(user.uid).set({
          'readNotices': noticeIds,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error marking all global notices as read: $e");
      rethrow; // UI에서 처리하도록 전파
    }
  }

  // 카테고리별 공지 일괄 읽음 처리 (최대 100개)
  Future<void> markAllNoticesAsRead(String category) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 해당 카테고리의 최근 100개 공지 ID 가져오기
      final snapshot = await _db
          .collection('notices')
          .where('category', isEqualTo: category)
          .orderBy('crawled_at', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) return;

      final noticeIds = snapshot.docs.map((doc) => doc.id).toList();

      // 사용자의 readNotices에 일괄 추가
      try {
        await _db.collection('users').doc(user.uid).update({
          'readNotices': FieldValue.arrayUnion(noticeIds),
        });
      } catch (e) {
        await _db.collection('users').doc(user.uid).set({
          'readNotices': noticeIds,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error marking notices as read for $category: $e");
      rethrow;
    }
  }

  // 핫 공지 (오늘 조회수 기준 Top 5)
  Stream<List<Notice>> getHotNotices() {
    String uid = _auth.currentUser!.uid;
    // 핫 공지도 스크랩/읽음 여부 표시를 위해 결합 스트림 사용 권장
    // 하지만 views_today 순으로 정렬해야 함.

    final noticeStream = _db
        .collection('notices')
        .orderBy('views_today', descending: true)
        .limit(5)
        .snapshots();

    final userStream = _db.collection('users').doc(uid).snapshots();

    return Rx.combineLatest2(noticeStream, userStream, (
      QuerySnapshot noticeSnapshot,
      DocumentSnapshot userSnapshot,
    ) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final scraps = List<String>.from(userData?['scraps'] ?? []);
      final readNotices = List<String>.from(userData?['readNotices'] ?? []);

      return noticeSnapshot.docs
          .map((doc) => Notice.fromFirestore(doc, scraps, readNotices))
          .toList();
    });
  }

  // 카테고리별 스마트 공지 개수 스트림 (읽지 않은 공지)
  Stream<int> getNoticeCount(String category) {
    String uid = _auth.currentUser!.uid;

    final noticeStream = _db
        .collection('notices')
        .where('category', isEqualTo: category)
        .orderBy('crawled_at', descending: true)
        .limit(20) // 성능 최적화: 최근 20개만 검사
        .snapshots();

    final userStream = _db.collection('users').doc(uid).snapshots();

    return Rx.combineLatest2(noticeStream, userStream, (
      QuerySnapshot noticeSnapshot,
      DocumentSnapshot userSnapshot,
    ) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final readNotices = List<String>.from(userData?['readNotices'] ?? []);

      int newCount = 0;
      for (var doc in noticeSnapshot.docs) {
        // 이미 읽은 공지는 카운트 제외
        if (!readNotices.contains(doc.id)) {
          newCount++;
        }
      }
      return newCount;
    });
  }

  // 전체 안 읽은 공지 개수 (알림 아이콘용)
  Stream<int> getTotalUnreadCount() {
    String uid = _auth.currentUser!.uid;

    final noticeStream = _db
        .collection('notices')
        .orderBy('crawled_at', descending: true)
        .limit(50) // 성능 최적화: 최근 50개만 검사
        .snapshots();

    final userStream = _db.collection('users').doc(uid).snapshots();

    return Rx.combineLatest2(noticeStream, userStream, (
      QuerySnapshot noticeSnapshot,
      DocumentSnapshot userSnapshot,
    ) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final readNotices = List<String>.from(userData?['readNotices'] ?? []);

      int newCount = 0;
      for (var doc in noticeSnapshot.docs) {
        if (!readNotices.contains(doc.id)) {
          newCount++;
        }
      }
      return newCount;
    });
  }

  // 전체 공지 카운트 메서드 (읽지 않은 공지)
  Stream<int> getWholeNoticeCount() {
    String uid = _auth.currentUser!.uid;

    final noticeStream = _db
        .collection('notices')
        .orderBy('crawled_at', descending: true)
        .limit(50)
        .snapshots();

    final userStream = _db.collection('users').doc(uid).snapshots();

    return Rx.combineLatest2(noticeStream, userStream, (
      QuerySnapshot noticeSnapshot,
      DocumentSnapshot userSnapshot,
    ) {
      final userData = userSnapshot.data() as Map<String, dynamic>?;
      final readNotices = List<String>.from(userData?['readNotices'] ?? []);

      int newCount = 0;
      for (var doc in noticeSnapshot.docs) {
        if (!readNotices.contains(doc.id)) {
          newCount++;
        }
      }
      return newCount;
    });
  }

  Future<void> updateLastNotificationCheck() async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).set({
      'last_notification_check': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      'crawled_at': FieldValue.serverTimestamp(), // 알림 카운트용, 직접 작성 시에도 추가
      'files': [],
    });
  }

  // 관리자 기능: 모든 긴급 공지 해제
  Future<void> resetAllUrgentNotices() async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('notices')
        .where('is_urgent', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'is_urgent': false});
    }
    await batch.commit();
  }

  // 관리자 기능: 모든 중요 공지 해제
  Future<void> resetAllImportantNotices() async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('notices')
        .where('is_important', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'is_important': false});
    }
    await batch.commit();
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
        .orderBy('createdAt', descending: true)
        .limit(50); // 최근 50개만

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

  Future<void> closeGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).update({
      'isManuallyClosed': true,
    });
  }

  // 모임 마감 취소 (재오픈)
  Future<void> reopenGroup(String groupId) async {
    await _db.collection('groups').doc(groupId).update({
      'isManuallyClosed': false,
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
      List<QnAItem> qnaList = qnaListDynamic
          .map((e) => QnAItem.fromMap(e))
          .toList();

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
      DocumentSnapshot userDoc = await transaction.get(
        _db.collection('users').doc(uid),
      );
      String lastName =
          (userDoc.data() as Map<String, dynamic>)['last_name'] ?? '';
      String firstName =
          (userDoc.data() as Map<String, dynamic>)['first_name'] ?? '';
      String userName = '$lastName$firstName';
      if (userName.isEmpty) userName = '익명';

      // 새 항목 생성
      QnAItem newItem = QnAItem(
        id: const Uuid()
            .v4(), // pubspec.yaml에 uuid 패키지 필요 (없을 시 string interpolation으로 대체)
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
  Future<void> updateQnA(
    String groupId,
    String qnaId,
    String newContent,
  ) async {
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
    return _db
        .collection('events')
        .orderBy('startDate')
        .limit(100) // 최근 100개만
        .snapshots()
        .map((snapshot) {
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

  // --- 5. 유저 관리 (관리자용) ---

  // 승인 대기 유저 목록 스트림
  Stream<List<Map<String, dynamic>>> getPendingUsers() {
    return _db
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['uid'] = doc.id; // UID 포함
            return data;
          }).toList();
        });
  }

  // 유저 승인
  Future<void> approveUser(String uid) async {
    await _db.collection('users').doc(uid).update({'status': 'approved'});
  }

  // 프로필 이미지 업데이트
  Future<String> updateProfileImage(String uid, File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$uid.jpg');

      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      await _db.collection('users').doc(uid).update({'profile_image_url': url});

      return url;
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  // 사용자 이름 업데이트 (성, 이름 분리)
  Future<void> updateUserName(
    String uid,
    String lastName,
    String firstName,
  ) async {
    try {
      await _db.collection('users').doc(uid).update({
        'last_name': lastName,
        'first_name': firstName,
      });
    } catch (e) {
      throw Exception('Failed to update user name: $e');
    }
  }

  // ★ 회원 탈퇴 (Account Deletion)
  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    try {
      // 1. Firestore에서 사용자 관련 데이터 삭제
      // (Batch를 사용해도 되지만, Auth 삭제 전 확실히 처리하기 위해 await)
      await _db.collection('users').doc(uid).delete();

      // 2. Firebase Auth에서 사용자 계정 삭제
      await user.delete();

      print('User account and Firestore data deleted successfully.');
    } on FirebaseAuthException catch (e) {
      // 계정 삭제 실패 시 (예: 최근 재로그인 필요)
      if (e.code == 'requires-recent-login') {
        throw '보안을 위해 로그아웃 후 다시 로그인해서 진행해주세요.';
      }
      throw '탈퇴 처리 중 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      print('Error deleting user data from Firestore: $e');
      throw '데이터 삭제 중 오류가 발생했습니다: $e';
    }
  }
}
