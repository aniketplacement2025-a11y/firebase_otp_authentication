import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  Future<bool> authenticateUser(String email, String password) async {
    try {
      // Fetch users from Realtime Database
      DatabaseEvent event = await _databaseRef.child('users').once();
      DataSnapshot snapshot = event.snapshot;

      if(snapshot.value !=null){
        // Convert the data to a Map
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

        // Check each user for matching credentials
        for(var userKey in users.keys){
          var user = users[userKey];
          if (user['email_id'] == email && user['password'] == password){
            return true; // Authentication successful
          }
        }
      }
      return false; // Authentication
    } catch (e){
      print('Authentication error: $e');
      return false;
    }
  }

  // Method to get all users (for testing)
 // Future<Map<dynamic, dynamic>?> getAllUsers() async {
 //    try {
 //      DatabaseEvent event = await _databaseRef.child('users').once();
 //      return event.snapshot.value as Map<dynamic, dynamic>?;
 //    } catch (e){
 //      print('Error fetching users: $e');
 //      return null;
 //    }
 //  }
}