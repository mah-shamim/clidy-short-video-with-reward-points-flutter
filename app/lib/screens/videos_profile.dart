import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:clidy/config/api.dart';

class VideosProfileScreen extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final int initialIndex;
  final String username;
  final String profileImageUrl;

  VideosProfileScreen({
    required this.videos,
    required this.initialIndex,
    required this.username,
    required this.profileImageUrl,
  });

  @override
  _VideosProfileScreenState createState() => _VideosProfileScreenState();
}

class _VideosProfileScreenState extends State<VideosProfileScreen> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeVideoPlayer(_currentIndex);
  }

  void _initializeVideoPlayer(int index) {
    if (_videoController != null) {
      _videoController!.dispose(); // Dispose of the previous controller
    }
    String videoUrl = API.getVideoUrl(widget.videos[index]['video_path']);
    _videoController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _videoController!.play();
      }).catchError((error) {
        print('Error initializing video: $error');
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController != null) {
      setState(() {
        _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _initializeVideoPlayer(index); // Reinitialize the video player for the new video
        },
        itemBuilder: (context, index) {
          return Stack(
            children: [
              // Video Player
              GestureDetector(
                onTap: _togglePlayPause,
                child: Center(
                  child: _videoController != null && _videoController!.value.isInitialized
                      ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                      : CircularProgressIndicator(),
                ),
              ),
              // Back button
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              // Action buttons (like, comment, share)
              Positioned(
                right: 10,
                bottom: 100,
                child: Column(
                  children: [
                    _buildActionButton(Icons.thumb_up, '1.2K'), // Likes
                    SizedBox(height: 20),
                    _buildActionButton(Icons.comment, '900'), // Comments
                    SizedBox(height: 20),
                    _buildActionButton(Icons.share, '58'), // Shares
                  ],
                ),
              ),
              // Profile image and username
              Positioned(
                bottom: 20,
                left: 10,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.profileImageUrl)
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                    SizedBox(width: 10),
                    Text(
                      widget.username,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              // Play/Pause overlay icon
              if (_videoController != null && !_videoController!.value.isPlaying)
                Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white.withOpacity(0.8),
                    size: 100,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _videoController != null && _videoController!.value.isInitialized
          ? FloatingActionButton(
        onPressed: _togglePlayPause,
        child: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
      )
          : null,
    );
  }

  // Build the action button (like, comment, share)
  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 35),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
