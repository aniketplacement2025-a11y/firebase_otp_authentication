import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_otp_authentication/screen/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String userEmail; // Add this

  const HomeScreen({
    super.key,
    required this.userEmail
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
              onPressed: () {
                //Just navigate back to login
                Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (_) => LoginScreen())
                );
              },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, $userEmail'),
      ),
    );
  }
}