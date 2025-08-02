import 'package:flutter/foundation.dart'; // Import to use kIsWeb
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:clidy/config/api.dart';
import 'package:clidy/components/comments_dialog.dart';

class ExploreVideoPlayerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final int initialIndex;

  ExploreVideoPlayerScreen({required this.videos, this.initialIndex = 0});

  @override
  _ExploreVideoPlayerScreenState createState() => _ExploreVideoPlayerScreenState();
}

class _ExploreVideoPlayerScreenState extends State<ExploreVideoPlayerScreen> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentPageIndex = 0;
  bool isLoading = true;
  int favoritesCount = 0;
  int commentCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentPageIndex = widget.initialIndex;
    _initializeVideo(_currentPageIndex);
  }

  Future<void> _initializeVideo(int index) async {
    _videoController?.dispose();
    final videoPath = widget.videos[index]['video_path'] ?? '';

    _videoController = VideoPlayerController.network(API.getVideoUrl(videoPath))
      ..initialize().then((_) {
        setState(() {
          isLoading = false;
          _videoController!.play();
        });
      });
    _videoController!.setLooping(true);
    await _loadVideoData(index);
  }

  Future<void> _loadVideoData(int index) async {
    try {
      final videoData = await API.getVideoData(widget.videos[index]['id'].toString());
      setState(() {
        favoritesCount = int.parse(videoData['favorites_count'].toString());
        commentCount = int.parse(videoData['comment_count'].toString());
      });
    } catch (e) {
      print('Error getting video data: $e');
    }
  }

  void _goToNextVideo() {
    if (_currentPageIndex < widget.videos.length - 1) {
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  void _goToPreviousVideo() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
                isLoading = true;
              });
              _initializeVideo(index);
            },
            itemBuilder: (context, index) {
              final videoData = widget.videos[index];
              return Stack(
                children: [
                  // Video Player
                  Center(
                    child: _videoController != null && _videoController!.value.isInitialized
                        ? (isWeb
                        ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                        : SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    ))
                        : Center(child: CircularProgressIndicator()),
                  ),
                  _buildUserOverlay(videoData['username'] ?? 'User', videoData['description'] ?? 'No description'),
                  if (isWeb) _buildWebIcons() else _buildMobileIcons(),
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.white, size: 28),
                          onPressed: () {
                            // Search action
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isWeb) _buildWebVideoControls(),
                ],
              );
            },
          ),
          if (isWeb) _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildUserOverlay(String username, String description) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black.withOpacity(0.5),
            child: Text(
              '@$username',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black.withOpacity(0.5),
            child: Text(
              description,
              style: TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebIcons() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconButton(Icons.favorite, favoritesCount, label: "Like"),
            SizedBox(height: 12),
            _buildIconButton(Icons.comment, commentCount, label: "Comments", onTap: () {
              showCommentsDialog(context, widget.videos[_currentPageIndex]['id'].toString());
            }),
            SizedBox(height: 12),
            _buildIconButton(Icons.share, 0, label: "Share"),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileIcons() {
    return Positioned(
      right: 20,
      bottom: 100,
      child: Column(
        children: [
          _buildIconButton(Icons.favorite, favoritesCount),
          SizedBox(height: 12),
          _buildIconButton(Icons.comment, commentCount, onTap: () {
            showCommentsDialog(context, widget.videos[_currentPageIndex]['id'].toString());
          }),
          SizedBox(height: 12),
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Sharing logic
            },
          ),
          Text(
            "Share",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWebVideoControls() {
    return Stack(
      children: [
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Icon(
              _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.white.withOpacity(0.8),
              size: 80,
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 10, //Timer position setting
          child: Text(
            "${_videoController!.value.position.inMinutes}:${(_videoController!.value.position.inSeconds % 60).toString().padLeft(2, '0')} / "
                "${_videoController!.value.duration.inMinutes}:${(_videoController!.value.duration.inSeconds % 60).toString().padLeft(2, '0')}",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, int count, {String label = '', VoidCallback? onTap}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onTap,
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        Text(
          isLoading ? '...' : count.toString(),
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned(
      right: 300,
      top: MediaQuery.of(context).size.height / 2 - 50,
      child: Column(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_upward, color: Colors.white, size: 30),
            onPressed: _goToPreviousVideo,
          ),
          SizedBox(height: 10),
          IconButton(
            icon: Icon(Icons.arrow_downward, color: Colors.white, size: 30),
            onPressed: _goToNextVideo,
          ),
        ],
      ),
    );
  }

}
