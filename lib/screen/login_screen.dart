import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
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
   _handleIncomingLinks();
 }

 @override
 void dispose(){
   _sub?.cancel();
   super.dispose();
 }

  void _handleIncomingLinks() {
   _handleInitialDynamicLink();
   _handleForegroundDynamicLinks();
  }

  void _handleInitialDynamicLink() async {
   try {
     final PendingDynamicLinkData? initialLink =
         await FirebaseDynamicLinksPlatform.instance.getInitialLink();

     if(initialLink != null){
       _signInWithEmailLink(initialLink.link.toString());
     }
   }catch(e){
     if(!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ErrorReceiving intitial Link: $e')),
     );
   }
  }

  void _handleForegroundDynamicLinks() {
    FirebaseDynamicLinksPlatform.instance.onLink.listen(
        (PendingDynamicLinkData dynamicLink){
          if(!mounted) return;
          _signInWithEmailLink(dynamicLink.link.toString());
        },
        onError: (err){
         if(!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error receiving link: $err')),
         );
       }
    );
  }

   Future<void> _signInWithEmailLink(String emailLink) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if(email == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Email not found in storage.')),
      );
      return;
    }

    if(_auth.isSignInWithEmailLink(emailLink)){
      try {
        await _auth.signInWithEmailLink(
            email: email,
            emailLink: emailLink
        );
      } catch(e){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in: $e')),
        );
      }
    }
   }

   Future<void> _sendSignInLink() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _emailController.text);

    var acs = ActionCodeSettings(
        url: firebaseProjectUrl,
        handleCodeInApp: true,
        iOSBundleId: iosBundleId,
        androidPackageName: androidPackageName,
        androidInstallApp: true,
        androidMinimumVersion: '12',
    );

    try {
      await _auth.sendSignInLinkToEmail(
          email: _emailController.text,
          actionCodeSettings: acs,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sign-in link sent to your email')),
      );
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending link: $e')),
      );
    }
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
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
                  onPressed: _sendSignInLink,
                  child: const Text('Send OTP'),
              ),
          ],
        ),
      ),
    );
  }
}