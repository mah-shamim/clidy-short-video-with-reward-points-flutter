import 'package:flutter/material.dart';

class UploadWeb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0E5EC), // Soft neumorphic background
      body: Center(
        child: Container(
          padding: EdgeInsets.all(25),
          constraints: BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(10, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                blurRadius: 20,
                offset: Offset(-10, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main icon with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.cloud_off,
                      color: Colors.blueGrey[600],
                      size: 80,
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Catchy title
              Text(
                "We're Working on This",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[800],
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10),

              // Main explanatory message
              Text(
                "The video upload feature will be available soon on the web version.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[500],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),

              // Additional message with positive tone
              Text(
                "In the meantime, try our mobile app to upload your videos instantly!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[400],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 30),

              // Button with hover animation
              MouseRegion(
                onEnter: (_) {},
                onExit: (_) {},
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Return to Home",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
