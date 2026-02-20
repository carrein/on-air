import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'icon_button_styled.dart';

/// Preview widget for links in the NoteInput (before sending).
/// Shows a simple indicator that a URL will be previewed.
class InputLinkPreview extends StatelessWidget {
  final String url;
  final VoidCallback onDismiss;

  const InputLinkPreview({
    super.key,
    required this.url,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
      ),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIcons.link(), color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link detected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Preview will be generated after sending',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          IconButtonStyled(
            icon: PhosphorIcons.x(),
            onPressed: onDismiss,
            size: 18,
            padding: 6,
          ),
        ],
      ),
    );
  }
}
