import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clidy/screens/profiles.dart';
import 'comments_dialog.dart';
import 'package:clidy/dialogs_alert/share_video.dart';

class HomeActions extends StatelessWidget {
  final bool isFavorite;
  final int favoriteCount;
  final int commentCount;
  final VoidCallback onFavoritePressed;
  final String profileImageUrl;
  final String userId;
  final String username;
  final String videoId;
  final String secureShareUrl;
  final String videoTitle;
  final String videoDescription;

  const HomeActions({
    Key? key,
    required this.isFavorite,
    required this.favoriteCount,
    required this.commentCount,
    required this.onFavoritePressed,
    required this.profileImageUrl,
    required this.userId,
    required this.username,
    required this.videoId,
    required this.secureShareUrl,
    this.videoTitle = '',
    this.videoDescription = '',
  }) : super(key: key);

  void _navigateToProfile(BuildContext context) {
    if (userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilesScreen(
            userId: userId,
            username: username,
            profileImageUrl: profileImageUrl,
          ),
        ),
      );
    } else {
      _showErrorSnackBar(context, 'Cant load profile.');
    }
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

  void _shareVideo(BuildContext context) {
    showShareDialog(
      context: context,
      username: username,
      secureShareUrl: secureShareUrl,
      videoTitle: videoTitle,
      videoDescription: videoDescription,
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToProfile(context),
      child: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: 23,
          backgroundImage: profileImageUrl.isNotEmpty
              ? NetworkImage(profileImageUrl)
              : null,
          onBackgroundImageError: (error, stackTrace) {
            print('Error loading profile image: $error');
          },
          // Fallback: show an icon if there is no image URL
          child: profileImageUrl.isEmpty
              ? Icon(Icons.person, color: Colors.white, size: 23)
              : null,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavoritePressed,
      child: Column(
        children: [
          Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.pink : Colors.white,
            size: 30,
          ),
          SizedBox(height: 5),
          Text(
            favoriteCount.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showCommentsDialog(context, videoId),
      child: Column(
        children: [
          Icon(
            Icons.comment,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(height: 5),
          Text(
            commentCount.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _shareVideo(context),
      child: Column(
        children: [
          Icon(
            Icons.share,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(height: 5),
          Text(
            'Share',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileButton(context),
          SizedBox(height: 20),
          _buildFavoriteButton(),
          SizedBox(height: 20),
          _buildCommentButton(context),
          SizedBox(height: 20),
          _buildShareButton(context),
        ],
      ),
    );
  }
}
