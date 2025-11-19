import 'package:flutter/material.dart';
import 'package:firebase_otp_authentication/screen/home_screen.dart';
import 'package:firebase_otp_authentication/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email');

    setState(() {
      _userEmail = userEmail;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user is logged in, go to HomeScreen
    if (_userEmail != null) {
      return HomeScreen(userEmail: _userEmail!); // Fix: Provide the email
    } else {
      // If not logged in, go to LoginScreen
      return const LoginScreen();
    }
  }
}