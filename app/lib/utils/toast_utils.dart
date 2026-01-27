import 'package:flutter/material.dart';

class ToastUtils {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // 이전 토스트가 있으면 즉시 제거 (새로운 메시지로 즉시 갱신)
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _FadingToast(
        message: message,
        isError: isError,
        onDismiss: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );

    // 오버레이 삽입
    Overlay.of(context).insert(_overlayEntry!);
  }
}

class _FadingToast extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _FadingToast({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_FadingToast> createState() => _FadingToastState();
}

class _FadingToastState extends State<_FadingToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 페이드 인/아웃 시간
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // 시작: 페이드 인
    _controller.forward();

    // 2초 후 페이드 아웃 및 제거
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 30 + bottomPadding, // 하단 여백 + 시스템 네비게이션 바 높이
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:
                  (widget.isError
                          ? const Color(0xFFE93D3D)
                          : const Color(0xFF3182F6))
                      .withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E8EB).withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (widget.isError
                              ? const Color(0xFFE93D3D)
                              : const Color(0xFF3182F6))
                          .withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
