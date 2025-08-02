import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:clidy/config/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clidy/screens/home.dart';

class PostVideo extends StatefulWidget {
  final String videoPath;
  final String? audioName;

  PostVideo({required this.videoPath, this.audioName});

  @override
  _PostVideoState createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
  VideoPlayerController? _videoController;
  List<dynamic> _hashtags = [];
  List<String> _selectedHashtags = [];
  File? _thumbnail;
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _fetchHashtags();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  Future<void> _fetchHashtags() async {
    try {
      final response = await http.post(
        Uri.parse(API.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"action": "getHashtags"}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _hashtags = data['hashtags'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hashtags.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting hashtags.')),
      );
    }
  }

  void _onHashtagSelected(String hashtag) {
    setState(() {
      if (_selectedHashtags.contains(hashtag)) {
        _selectedHashtags.remove(hashtag);
      } else if (_selectedHashtags.length < 5) {
        _selectedHashtags.add(hashtag);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You cannot select more than 5 hashtags.')),
        );
      }
    });
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) => Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Select from gallery'),
              onTap: () async {
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _thumbnail = File(pickedFile.path);
                  });
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a photo'),
              onTap: () async {
                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _thumbnail = File(pickedFile.path);
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error when selecting thumbnail.')),
      );
    }
  }

  Future<void> _uploadVideo() async {
    if (_thumbnail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a thumbnail')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unidentified user')),
      );
      return;
    }

    final description = _descriptionController.text;

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a description')),
      );
      return;
    }

    try {
      final videoBytes = File(widget.videoPath).readAsBytesSync();
      final thumbnailBytes = _thumbnail!.readAsBytesSync();

      final response = await http.post(
        Uri.parse(API.baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "uploadVideo",
          "user_id": userId,
          "description": description,
          "hashtags": _selectedHashtags,
          "video_data": base64Encode(videoBytes),
          "thumbnail_data": base64Encode(thumbnailBytes),
          "music_file": widget.audioName ?? '',
          "review_status": 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video uploaded successfully!')),
          );

          await API.getUserPoints();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VideoFeedUI()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${data['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server connection error')),
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Publish Video", style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(8.0),
                child: _videoController != null && _videoController!.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: 16 / 9, // Smallest aspect ratio
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: VideoPlayer(_videoController!),
                      ),
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      ),
                    ],
                  ),
                )
                    : Center(child: CircularProgressIndicator()),
              ),
              SizedBox(height: 15),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _hashtags.map((hashtag) {
                  final hashtagName = hashtag['name'];
                  return ChoiceChip(
                    label: Text('#$hashtagName', style: TextStyle(fontSize: 12)),
                    selected: _selectedHashtags.contains(hashtagName),
                    onSelected: (_) => _onHashtagSelected(hashtagName),
                    selectedColor: Colors.pinkAccent.withOpacity(0.2),
                    backgroundColor: Colors.grey[700],
                    labelStyle: TextStyle(
                      color: _selectedHashtags.contains(hashtagName) ? Colors.pinkAccent : Colors.white,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 15),
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: 120,
                  child: _thumbnail != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _thumbnail!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Center(
                    child: Text(
                      'Select a thumbnail',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _descriptionController,
                style: TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Describe your video...',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadVideo,
        label: Text('Post'),
        icon: Icon(Icons.upload),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }
}
