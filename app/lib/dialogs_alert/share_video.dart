// share_video.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void showShareDialog({
  required BuildContext context,
  required String username,
  required String secureShareUrl, // Now we pass the backend secure link
  required String videoTitle,
  required String videoDescription,
}) {
  String shareMessage = 'Watch this amazing video of $username in your app name!\n\n';
  if (videoTitle.isNotEmpty) {
    shareMessage += '📌 $videoTitle\n';
  }
  if (videoDescription.isNotEmpty) {
    shareMessage += '📝 $videoDescription\n\n';
  }
  shareMessage += '👉 $secureShareUrl'; // We use the secure link

  final encodedMessage = Uri.encodeComponent(shareMessage);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black.withOpacity(0.9),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Share via',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  context: context,
                  icon: Icons.message,
                  label: 'SMS',
                  color: Colors.green,
                  onTap: () async {
                    final smsUrl = 'sms:?body=$encodedMessage';
                    if (await canLaunchUrl(Uri.parse(smsUrl))) {
                      await launchUrl(Uri.parse(smsUrl));
                    } else {
                      _showErrorSnackBar(context, 'Could not open SMS');
                    }
                  },
                ),
                _buildShareOption(
                  context: context,
                  icon: Icons.copy,
                  label: 'Copy Link',
                  color: Colors.blue,
                  onTap: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: shareMessage));
                      Navigator.pop(context); // close BottomSheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Link copied to clipboard'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      print("Error copying to clipboard: $e");
                      _showErrorSnackBar(context, 'The link could not be copied.');
                    }
                  },
                ),
                _buildShareOption(
                  context: context,
                  icon: Icons.email,
                  label: 'Email',
                  color: Colors.red,
                  onTap: () async {
                    final emailUrl = 'mailto:?subject=Video shared from your app&body=$encodedMessage';
                    if (await canLaunchUrl(Uri.parse(emailUrl))) {
                      await launchUrl(Uri.parse(emailUrl));
                    } else {
                      _showErrorSnackBar(context, 'Email could not be opened');
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

Widget _buildShareOption({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: () {
      onTap();
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
