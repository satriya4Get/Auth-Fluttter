import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? avatarUrl;
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data from Firestore when initialized
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print('User signed in with UID: ${user.uid}');  // Debug: Check if user is signed in
      try {
        // Retrieve data from Firestore collection 'biodata'
        DocumentSnapshot biodataDoc = await FirebaseFirestore.instance
            .collection('biodata')
            .doc(user.uid)
            .get();

        // Debug: Check if the document exists
        if (biodataDoc.exists) {
          print('Biodata document exists: ${biodataDoc.data()}');  // Debug: Print the data

          setState(() {
            userName = biodataDoc['nama'];  // Assign 'nama' to userName
            avatarUrl = biodataDoc['imageUrl'];  // Assign 'imageUrl' to avatarUrl
          });

          print('User name: $userName, Avatar URL: $avatarUrl');  // Debug: Check assigned values
        } else {
          print('Biodata document does not exist for UID: ${user.uid}');
        }
      } catch (e) {
        print('Failed to load user data: $e');  // Debug: Print error
      }
    } else {
      print('No user is signed in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              userName ?? "User",  // Display name from Firestore
              style: const TextStyle(color: Colors.white),
            ),
            accountEmail: null,  // Hiding the email field
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)  // Display avatar from Firestore
                  : null,  // If no avatar URL, display initials
              child: avatarUrl == null
                  ? Text(
                      userName?.isNotEmpty == true
                          ? userName![0].toUpperCase()  // Display initial if no avatar
                          : "U",  // Fallback if no userName
                      style: const TextStyle(fontSize: 40.0, color: Colors.blue),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/image.png"), // Background image
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  print('Error loading background image: $exception');
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(userName ?? "Logout"),
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                print("Signed Out");
                Navigator.pushReplacementNamed(context, '/signin');
              });
            },
          ),
        ],
      ),
    );
  }
}
