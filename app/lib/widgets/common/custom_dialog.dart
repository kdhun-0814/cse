import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final String? contentText;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const CustomDialog({
    super.key,
    required this.title,
    this.content,
    this.contentText,
    this.confirmText = "확인",
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  }) : assert(content != null || contentText != null,
            "Either content or contentText must be provided");

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191F28),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (contentText != null)
              Text(
                contentText!,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4E5968),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
            else if (content != null)
              Flexible(child: SingleChildScrollView(child: content!)),
            const SizedBox(height: 24),
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: const Color(0xFFF2F4F6),
                      ),
                      child: Text(
                        cancelText!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7684),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: isDestructive
                          ? const Color(0xFFFF4E4E) // Brand Red
                          : const Color(0xFF3182F6), // Brand Blue
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
