import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_otp_authentication/screen/home_screen.dart';
import 'package:firebase_otp_authentication/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_otp_authentication/firebase_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 final _emailController = TextEditingController();
 final _passwordController = TextEditingController();
 final AuthService _authService = AuthService();
 final _auth = FirebaseAuth.instance;
 bool _isLoading = false;
 StreamSubscription? _sub;
 bool _isForgotPassword = false;

 @override
 void initState(){
   super.initState();
 }

  Future<void> _sendOTP() async {
   try {
     String email = _emailController.text.trim();

     if(email.isEmpty || !email.contains('@')){
       _showMessage('Please enter a valid email address');
       return;
     }

     setState(() {
       _isLoading = true;
     });

     await receviedOTP(email);

     setState(() {
       _isLoading = false;
     });

     _showMessage('OTP sent to your email! Check your inbox.');
   } catch(e) {
     setState(() {
       _isLoading = false;
     });
     _showMessage('Error sending OTP: $e');
   }
  }

  // Send OTP to email
  Future<void> receviedOTP(String email) async {
    try {
      // Send email for later use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('otp_email', email);

      // Configure action code settings
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
          url: 'https://fir-otpauthentication-4f013.firebaseapp.com',
         // Your Firebase project URL
          handleCodeInApp: true,
          iOSBundleId: iosBundleId,
          androidPackageName: androidPackageName,
          androidInstallApp: true,
          androidMinimumVersion: '17',
      );

      // Sand sign-in link to email
      await _auth.sendSignInLinkToEmail(
          email: email,
          actionCodeSettings: actionCodeSettings
      );

      print('OTP sent to $email');
    } catch(e) {
      print('Error sending OTP: $e');
      rethrow;
    }
  }

  // Verify OTP from the link
  Future<User?> verifyOTP(String emailLink) async {
   try {
     if(_auth.isSignInWithEmailLink(emailLink)){
       // Get the stored email
       final prefs = await SharedPreferences.getInstance();
       final email = prefs.getString('otp_email');

       if(email == null){
         throw Exception('Email not found. Please request OTP again.');
       }

       // Sign in with email link
       UserCredential userCredential = await _auth.signInWithEmailLink(
           email: email,
           emailLink: emailLink
       );

       // Clear stored email successful verification
       await prefs.remove('otp_email');

       //Navigate to home screen
       Navigator.pushReplacement(
           context, MaterialPageRoute(
           builder: (_) => HomeScreen(userEmail: email))
       );

       return userCredential.user;
     }
     return null;
   } catch(e){
     print('Error verifying OTP: $e');
     rethrow;
   }
  }

  // Check if user is logged in
 User? getCurrentUser(){
   return _auth.currentUser;
 }

 // Sign Out
 Future<void> signOut() async {
   await _auth.signOut();
 }

   Future<void> _signInWithEmailAndPassword() async {
   try {
     String email = _emailController.text.trim();
     String password = _passwordController.text.trim();

     if(email.isEmpty || password.isEmpty){
       // ScaffoldMessenger.of(context).showSnackBar(
       //   SnackBar(content: Text('Please Fill all fields')),
       // );
       _showMessage('Please Fill all fields');
       return;
     }

     setState(() {
       _isLoading = true;
     });

     bool isAuthenticated = await _authService.authenticateUser(email, password);

     setState(() {
       _isLoading = false;
     });

     if(isAuthenticated){
       //Navigate to home screen
        Navigator.pushReplacement(
            context, MaterialPageRoute(
            builder: (_) => HomeScreen(userEmail: email))
        );
     } else {
       // ScaffoldMessenger.of(context).showSnackBar(
       //   SnackBar(content: Text('Invalid $email or $password')),
       // );
       _showMessage('Invalid $email or $password');
     }
   } catch (e){
     // ScaffoldMessenger.of(context).showSnackBar(
     //   SnackBar(content: Text('Error signing in: $e')),
     // );
     _showMessage('Error signing in: $e');
    }
   }

   void _showMessage(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      )
    );
   }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
                onPressed: _signInWithEmailAndPassword,
                child: const Text('Submit'),
            ),
            TextButton(
                onPressed: (){
                   setState(() {
                    _isForgotPassword = true; 
                   });
                  }, 
                child: const Text('Forgot password'),
            ),
            if(_isForgotPassword)
              ElevatedButton(
                  onPressed: _sendOTP,
                  child: const Text('Send OTP'),
              ),
          ],
        ),
      ),
    );
  }
}