import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clidy/layout/record_timer.dart'; // Import the timer file
import 'package:clidy/layout/video_record.dart'; //Import the video recording screen

class UploadVideo extends StatefulWidget {
  @override
  _UploadVideoState createState() => _UploadVideoState();
}

class _UploadVideoState extends State<UploadVideo> {
  CameraController? _cameraController;
  bool _is15SecondsSelected = true;
  final ImagePicker _picker = ImagePicker(); // Create an instance of ImagePicker
  bool _isRecording = false; // Recording status
  XFile? _videoFile; // Recorded video file

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // Initialize the camera
  }

  @override
  void dispose() {
    _cameraController?.dispose(); // Release camera resources
    super.dispose();
  }

  // Initialize the camera
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;

      _cameraController = CameraController(camera, ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  // Function to select a video from the gallery
  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        _videoFile = video;
      });
      _navigateToVideoRecord(); // Navigate to the VideoRecord screen with the video selected
    }
  }

  // Function to start recording
  Future<void> _startRecording() async {
    if (_cameraController != null && _cameraController!.value.isInitialized && !_isRecording) {
      setState(() {
        _isRecording = true;
      });

      int maxSeconds = _is15SecondsSelected ? 15 : 30;

      // Start video recording
      try {
        print("Starting recording...");
        await _cameraController!.startVideoRecording();
        print("Recording started successfully.");

        // Show timer before starting recording
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent the dialog from closing by tapping outside
          builder: (BuildContext context) {
            return RecordTimer(
              maxSeconds: maxSeconds,
              onFinish: () async {
                print("Timer ended, stopping recording...");
                // Stop recording when timer ends
                await _stopRecording();
                Navigator.of(context).pop(); // Close the timer dialog

                // Navigate to the video playback screen
                _navigateToVideoRecord();
              },
            );
          },
        );
      } catch (e) {
        print('Error starting recording: $e');
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  // Function to stop recording
  Future<void> _stopRecording() async {
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      try {
        XFile videoFile = await _cameraController!.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _videoFile = videoFile; // Save file video
        });
        print('Saved video file: ${_videoFile!.path}');
      } catch (e) {
        print('Error stopping recording: $e');
        setState(() {
          _isRecording = false; // Make sure to change the recording state even if it fails
        });
      }
    }
  }

  // Function to navigate to the VideoRecord screen with the recorded video
  void _navigateToVideoRecord() {
    if (_videoFile != null && _videoFile!.path.isNotEmpty) {
      print("Navigating to VideoRecordScreen with path: ${_videoFile!.path}");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoRecordScreen(
            videoPath: _videoFile!.path, // Pass the path of the recorded video
          ),
        ),
      );
    } else {
      print('Error: Could not get video file');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show the camera view if it is initialized
          _cameraController != null && _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : Center(child: CircularProgressIndicator()),

          // Top left button to close
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.pink, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Buttons at the top right
          Positioned(
            top: 40,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.flip_camera_android, color: Colors.pink, size: 30),
              onPressed: () {
                // Action to change the camera (front/rear)
              },
            ),
          ),

          // Timer for recording
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _is15SecondsSelected = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: _is15SecondsSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '15s',
                      style: TextStyle(
                        color: _is15SecondsSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _is15SecondsSelected = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_is15SecondsSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '30s',
                      style: TextStyle(
                        color: !_is15SecondsSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Record and gallery button
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Button to select from gallery
                IconButton(
                  icon: Icon(Icons.photo, color: Colors.white, size: 30),
                  onPressed: _pickVideo, // Select only video from gallery
                ),
                SizedBox(width: 20),

                // Record button
                GestureDetector(
                  onTap: () {
                    _startRecording(); // Start recording with timer
                  },
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                    child: Icon(
                      Icons.videocam, // Show camcorder icon
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}