import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../models/event.dart';
import '../../services/firestore_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/common/custom_loading_indicator.dart';
import '../../widgets/common/custom_dialog.dart';
import 'event_add_screen.dart';
import 'event_edit_screen.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Event>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.getEvents();
  }

  // 삭제 확인 다이얼로그
  void _confirmDelete(Event event) {
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "일정 삭제",
        contentText: "정말로 이 일정을 삭제하시겠습니까?",
        cancelText: "취소",
        confirmText: "삭제",
        isDestructive: true,
        onConfirm: () async {
          await _firestoreService.deleteEvent(event.id);
          if (mounted) {
            Navigator.pop(ctx);
            ToastUtils.show(context, "삭제되었습니다.");
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text(
          '일정 관리 (관리자)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF191F28),
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: StreamBuilder<List<Event>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("일정을 불러오지 못했습니다."));
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text(
                "등록된 일정이 없습니다.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // 날짜순 정렬 (최신순? or 다가오는 순?)
          // 관리 페이지이므로 날짜 역순(최신 등록이 위? 혹은 날짜 먼 것이 위?)
          // 보통 일정 관리는 날짜 순서대로 보는 것이 편함.
          // 여기서는 시작일 기준 오름차순으로 정렬하겠습니다.
          events.sort((a, b) => a.startDate.compareTo(b.startDate));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventItem(event);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EventAddScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF3182F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventItem(Event event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(event.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.5,
          children: [
            CustomSlidableAction(
              onPressed: (context) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventEditScreen(event: event),
                  ),
                );
              },
              backgroundColor: const Color(0xFF3182F6).withOpacity(0.8), // 투명도 적용
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, size: 28),
                  SizedBox(height: 4),
                  Text("수정", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            CustomSlidableAction(
              onPressed: (context) {
                _confirmDelete(event);
              },
              backgroundColor: const Color(0xFFE93D3D).withOpacity(0.8), // 투명도 적용
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 28),
                  SizedBox(height: 4),
                  Text("삭제", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E8EB)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: event.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333D4B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: event.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.dateRangeText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
