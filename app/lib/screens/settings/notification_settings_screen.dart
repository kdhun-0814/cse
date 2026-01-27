import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

import 'package:flutter/services.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text(
          "알림 센터 설정",
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF191F28)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("설정을 불러오는 중 오류가 발생했습니다."));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final settings =
              data['notification_settings'] as Map<String, dynamic>? ?? {};

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  "일반 공지 알림",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B95A1),
                  ),
                ),
              ),
              _buildSettingItem(
                "학사 공지",
                "학사",
                settings['학사'] ?? true,
                Icons.school_rounded,
                Colors.blue[700]!,
              ),
              _buildSettingItem(
                "장학 공지",
                "장학",
                settings['장학'] ?? true,
                Icons.emoji_events_rounded,
                Colors.orange[700]!,
              ),
              _buildSettingItem(
                "취업/진로",
                "취업",
                settings['취업'] ?? true,
                Icons.work_rounded,
                Colors.green[700]!,
              ),
              _buildSettingItem(
                "학과 행사",
                "학과행사",
                settings['학과행사'] ?? true,
                Icons.celebration_rounded,
                Colors.purple[700]!,
              ),
              _buildSettingItem(
                "외부 행사",
                "외부행사",
                settings['외부행사'] ?? true,
                Icons.public_rounded,
                Colors.grey[700]!,
              ),
              _buildSettingItem(
                "공모전",
                "공모전",
                settings['공모전'] ?? true,
                Icons.lightbulb_rounded,
                Colors.amber[700]!,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String key,
    bool value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: SwitchListTile(
        value: value,
        onChanged: (newValue) {
          HapticFeedback.lightImpact();
          _firestoreService.toggleNotificationSetting(key, newValue);
        },
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333D4B),
              ),
            ),
          ],
        ),
        activeColor: const Color(0xFF3182F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }
}
