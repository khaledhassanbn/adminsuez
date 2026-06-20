import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/support_message.dart';
import 'image_viewer_dialog.dart';
import '../../theme/app_color.dart';

class AdminChatBubble extends StatelessWidget {
  final SupportMessage message;

  const AdminChatBubble({
    super.key,
    required this.message,
  });

  String _formatTime(DateTime dateTime) {
    return intl.DateFormat('h:mm a', 'ar').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (message.isFromSystem) {
      return _buildSystemBubble(context);
    }

    final isMe = message.isFromAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe) ...[
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.mainColor,
                  child: Icon(Icons.support_agent, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe 
                        ? AppColors.mainColor 
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? Radius.zero : const Radius.circular(16),
                      bottomRight: isMe ? const Radius.circular(16) : Radius.zero,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عرض الصورة إذا كانت موجودة
                      if (message.hasImage) ...[
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => ImageViewerDialog(
                                imageUrl: message.imageUrl!,
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: message.imageUrl!,
                              placeholder: (context, url) => const SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.image_not_supported_rounded,
                                size: 40,
                              ),
                              maxWidthDiskCache: 1024,
                              maxHeightDiskCache: 1024,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (message.text != null && message.text!.isNotEmpty)
                          const SizedBox(height: 8),
                      ],
                      if (message.text != null && message.text!.isNotEmpty)
                        Text(
                          message.text!,
                          style: TextStyle(
                            color: isMe ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[400],
                  child: const Icon(Icons.person, size: 14, color: Colors.white),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 36 : 16,
              right: isMe ? 16 : 36,
              top: 4,
            ),
            child: Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.amber,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    message.text ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
