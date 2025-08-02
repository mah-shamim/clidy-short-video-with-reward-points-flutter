import 'package:flutter/material.dart';
import 'package:clidy/config/api.dart'; // import config api

void showCommentsDialog(BuildContext context, String videoId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Transparent background outside the modal
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5, // Occupies 50% of the screen initially
        minChildSize: 0.3,     // Occupies at least 30% of the screen
        maxChildSize: 0.8,     // Occupies a maximum of 80% of the screen
        builder: (context, scrollController) {
          return CommentsSection(videoId: videoId);
        },
      );
    },
  );
}

class CommentsSection extends StatefulWidget {
  final String videoId;

  const CommentsSection({required this.videoId});

  @override
  _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<dynamic> comments = [];
  TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  // Method to get the comments from the API
  void _fetchComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> fetchedComments = await API.getComments(widget.videoId);
      setState(() {
        comments = fetchedComments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting comments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to post a comment
  void _postComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      await API.addComment(widget.videoId, _commentController.text);
      _commentController.clear();
      _fetchComments(); // Update the comments list
    } catch (e) {
      print('Error posting comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C), // Use dark gray
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Title and close button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${comments.length} Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context); // Close the modal
                  },
                ),
              ],
            ),
          ),

          Divider(color: Colors.white, height: 1),

          // List of comments
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator()) // Show a loading indicator while comments are loading
                : ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return _buildCommentItem(comment);
              },
            ),
          ),

          Divider(color: Colors.white, height: 1),

          // Text field to add a comment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add comment...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[700],
                      filled: true,
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: _postComment, // Post comment
                  child: CircleAvatar(
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for each individual comment
  Widget _buildCommentItem(dynamic comment) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          CircleAvatar(
            backgroundImage: comment['profile_image'] != null
                ? NetworkImage(API.getProfileImageUrl(comment['profile_image']))
                : AssetImage('assets/default_profile.png') as ImageProvider, // Default image if you do not have a profile image
          ),
          SizedBox(width: 10),

          // Comment information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del usuario
                Text(
                  comment['username'] ?? 'User',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 5),

                // Comment text
                Text(comment['comment'] ?? '', style: TextStyle(color: Colors.white)),
                SizedBox(height: 5),

                // Interaction options (for example: reply or like)
                Row(
                  children: [
                    Text(
                      comment['created_at'] ?? '', // Comment date
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Spacer(),
                    Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                    SizedBox(width: 5),
                    Text('7', style: TextStyle(color: Colors.grey)), // You can update this number with the actual value
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
