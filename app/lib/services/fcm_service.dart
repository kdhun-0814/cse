import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// FCM 초기화 및 토큰 저장
  Future<void> initialize() async {
    // 알림 권한 요청
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM 권한 승인됨');

      // 토큰 가져오기 및 저장
      await _saveToken();

      // 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen(_onTokenRefresh);
    } else {
      print('⚠️ FCM 권한 거부됨');
    }
  }

  /// FCM 토큰 저장
  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      final uid = _auth.currentUser?.uid;

      if (token != null && uid != null) {
        await _db.collection('users').doc(uid).update({
          'fcm_token': token,
          'fcm_token_updated_at': FieldValue.serverTimestamp(),
        });
        print('✅ FCM 토큰 저장: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ FCM 토큰 저장 실패: $e');
    }
  }

  /// 토큰 갱신 핸들러
  Future<void> _onTokenRefresh(String newToken) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'fcm_token': newToken,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
      });
      print('🔄 FCM 토큰 갱신: ${newToken.substring(0, 20)}...');
    }
  }

  /// 포그라운드 메시지 핸들러 설정
  void setupForegroundHandler(Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  /// 백그라운드 메시지 클릭 핸들러 설정
  void setupMessageOpenedHandler(Function(RemoteMessage) onMessageOpened) {
    // 앱이 백그라운드에서 알림 클릭으로 열렸을 때
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpened);

    // 앱이 종료 상태에서 알림 클릭으로 열렸을 때
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        onMessageOpened(message);
      }
    });
  }
}
