import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb
import 'package:clidy/screens/login.dart'; // screen login
import 'package:clidy/screens/home.dart'; // screen home
import 'components/splash_screen.dart'; // screen splash
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clidy App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreenWrapper(),
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  @override
  _SplashScreenWrapperState createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Function to check session status and navigate
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Check if the platform is Web
    if (kIsWeb) {
      // On Web, browse immediately without showing SplashScreen
      setState(() {
        _isLoggedIn = isLoggedIn;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _isLoggedIn ? VideoFeedUI() : LoginScreen(),
        ),
      );
    } else {
      // On mobile, shows the SplashScreen with a 2 second delay
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _isLoggedIn = isLoggedIn;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _isLoggedIn ? VideoFeedUI() : LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If it is Web, it directly returns the login or home screen, without the Splash
    if (kIsWeb) {
      return _isLoggedIn ? VideoFeedUI() : LoginScreen();
    } else {
      // On mobile, show the SplashScreen
      return SplashScreen();
    }
  }
}
