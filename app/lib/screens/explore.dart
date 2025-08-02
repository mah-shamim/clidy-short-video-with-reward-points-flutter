import 'package:flutter/material.dart';
import 'package:clidy/config/api.dart';
import 'package:clidy/components/explore_video_player.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchVideos(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<dynamic> videos = await API.searchVideos(query);
      setState(() {
        _searchResults = videos.map((video) => Map<String, dynamic>.from(video)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error when searching for videos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Center(
                  child: Container(
                    width: 400,
                    child: _buildSearchBar(isWeb: true),
                  ),
                );
              } else {
                return _buildSearchBar(isWeb: false);
              }
            },
          ),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: _isLoading
          ? _buildLoadingIndicator()
          : _searchResults.isEmpty
          ? _buildEmptyResults()
          : _buildGridView(),
    );
  }

  Widget _buildSearchBar({required bool isWeb}) {
    return TextField(
      controller: _searchController,
      onSubmitted: (query) => _searchVideos(query),
      style: TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: isWeb ? Colors.grey[800] : Colors.grey[850],
        hintText: 'Search videos...',
        hintStyle: TextStyle(color: Colors.white54, fontSize: isWeb ? 16 : 14),
        prefixIcon: Icon(Icons.search, color: Colors.white),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isWeb ? 25 : 30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Searching for videos...',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Text(
        'No results found',
        style: TextStyle(color: Colors.white70, fontSize: 18),
      ),
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double aspectRatio;

        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
          aspectRatio = 4 / 5;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
          aspectRatio = 4 / 5;
        } else {
          crossAxisCount = 2;
          aspectRatio = 9 / 16;
        }

        return GridView.builder(
          padding: EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            return _buildThumbnailItem(index);
          },
        );
      },
    );
  }

  Widget _buildThumbnailItem(int index) {
    final video = _searchResults[index];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExploreVideoPlayerScreen(
              videos: _searchResults, // Passing the full list of videos
              initialIndex: index, // Passing the initial index of the selected video
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                API.getThumbnailUrl(video['thumbnail'] ?? ''),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['description'] ?? 'No description',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        video['uploadDate'] ?? '1 day ago',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '${video['likes'] ?? 0}K',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
