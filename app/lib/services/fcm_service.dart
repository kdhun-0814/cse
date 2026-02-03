import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 로컬 알림 플러그인
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isLocalNotificationInitialized = false;

  /// FCM 초기화 및 토큰 저장
  Future<void> initialize() async {
    // 1. 알림 권한 요청 (iOS/Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM 권한 승인됨');

      // 2. iOS 포그라운드 알림 설정 (앱 켜져있을 때도 알림 보이게)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. 로컬 알림 초기화 (Android 채널 등)
      await _setupLocalNotifications();

      // 4. 토큰 저장 및 리스너 등록
      await _saveToken();
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // 5. 주제 구독: 전체 공지 채널
      await _messaging.subscribeToTopic('notice');
      print('✅ Topic "notice" 구독 완료');

      // 6. 포그라운드 메시지 리스너 등록
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    } else {
      print('⚠️ FCM 권한 거부됨');
    }
  }

  /// 로컬 알림 설정 (Android 채널 생성 등)
  Future<void> _setupLocalNotifications() async {
    if (_isLocalNotificationInitialized) return;

    // Android 설정
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // 기본 아이콘 사용

    // iOS 설정
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ★ FIX: Correctly use ONLY named parameters for initialize
    await _localNotifications.initialize(
      /* settings: */
      // Removed comment to avoid confusion, using named param directly
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
      },
    );

    // Android용 알림 채널 생성 (필수)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _isLocalNotificationInitialized = true;
    print('✅ 로컬 알림(Foregound) 설정 완료');
  }

  /// 포그라운드에서 알림 수신 시 로컬 알림으로 표시
  void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      // Android는 앱이 켜져있을 때 FCM이 자동으로 알림을 안 띄워주므로 직접 띄움
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // Positional
            'High Importance Notifications', // Positional
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
    // iOS는 foregoundPresentationOptions 설정 덕분에 자동으로 뜸
    print('🔔 포그라운드 알림 수신: ${notification?.title}');
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
        print('✅ FCM 토큰 저장: $token');
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
}
