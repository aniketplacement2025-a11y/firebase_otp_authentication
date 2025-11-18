import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
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
 final _auth = FirebaseAuth.instance;
 StreamSubscription? _sub;

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
            ElevatedButton(
                onPressed: _sendSignInLink,
                child: const Text('Send Sign-In Link'),
            ),
          ],
        ),
      ),
    );
  }

}