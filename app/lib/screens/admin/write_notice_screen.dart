import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../widgets/common/custom_loading_indicator.dart';
import '../../services/firestore_service.dart';
import '../../utils/toast_utils.dart';

class WriteNoticeScreen extends StatefulWidget {
  const WriteNoticeScreen({super.key});

  @override
  State<WriteNoticeScreen> createState() => _WriteNoticeScreenState();
}

class _WriteNoticeScreenState extends State<WriteNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  String _title = '';
  String _content = '';
  String _link = '';
  String _category = '외부행사'; // 기본값
  bool _isImportant = false;
  bool _isUrgent = false;

  final List<String> _categories = [
    '학사',
    '장학',
    '취업',
    '학과행사', // Department Event included
    '외부행사',
    '공모전',
  ];

  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 1. 이미지 업로드
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('notices') // external_events -> notices
            .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');

        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // 2. DB 저장
      await _firestoreService.createNotice(
        title: _title,
        content: _content,
        category: _category,
        link: _link,
        imageUrls: imageUrls,
        isImportant: _isImportant,
        isUrgent: _isUrgent,
      );

      if (mounted) {
        ToastUtils.show(context, "공지사항이 등록되었습니다.");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, "등록 실패: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "공지사항 작성 (관리자)",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomLoadingIndicator(
                      color: Colors.white,
                      size: 20,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "등록",
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 선택
              const Text("카테고리", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF2F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 설정 (중요 / 긴급)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "⭐ 중요 공지로 등록",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _isImportant,
                onChanged: (val) => setState(() => _isImportant = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "🚨 긴급 공지로 등록",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("7일간 홈 화면 최상단에 노출됩니다."),
                value: _isUrgent,
                onChanged: (val) => setState(() => _isUrgent = val),
              ),
              const Divider(),
              const SizedBox(height: 16),

              // 제목
              const Text("제목", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "제목을 입력하세요",
                  filled: true,
                  fillColor: const Color(0xFFF2F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => val!.isEmpty ? "제목을 입력해주세요." : null,
                onSaved: (val) => _title = val!,
              ),
              const SizedBox(height: 24),

              // 내용
              const Text("내용", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "내용을 입력하세요",
                  filled: true,
                  fillColor: const Color(0xFFF2F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) => val!.isEmpty ? "내용을 입력해주세요." : null,
                onSaved: (val) => _content = val!,
              ),
              const SizedBox(height: 24),

              // 링크
              const Text(
                "관련 링크 (선택)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "URL을 입력하세요 (예: https://...)",
                  filled: true,
                  fillColor: const Color(0xFFF2F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSaved: (val) => _link = val ?? '',
              ),
              const SizedBox(height: 24),

              // 이미지
              const Text(
                "이미지 첨부",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E8EB)),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Color(0xFF8B95A1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ..._selectedImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final image = entry.value;
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(image.path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
