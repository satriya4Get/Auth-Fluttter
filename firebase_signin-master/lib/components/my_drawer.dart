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
    _loadUserData(); // Memuat data pengguna dari Firestore
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Mengambil data user dari Firestore berdasarkan UID pengguna
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            userName = userDoc['nama'];  // Mengambil nama dari Firestore
            avatarUrl = userDoc['imageUrl'];  // Mengambil URL gambar dari Firestore
          });
        }
      } catch (e) {
        print('Failed to load user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              userName ?? "User",  // Menampilkan nama dari Firestore
              style: const TextStyle(color: Colors.white),
            ),
            accountEmail: Text(
              user?.email ?? "email@example.com",
              style: const TextStyle(color: Color.fromARGB(255, 251, 247, 247)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)  // Menampilkan avatar dari Firestore
                  : null,  // Jika avatar tidak ditemukan, tampilkan inisial
              child: avatarUrl == null
                  ? Text(
                      userName?.isNotEmpty == true
                          ? userName![0].toUpperCase()  // Menampilkan inisial dari nama
                          : "U",  // Fallback jika nama pengguna tidak ada
                      style: const TextStyle(fontSize: 40.0, color: Colors.blue),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/image.png"),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  print('Error loading image: $exception');
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
          // Tambahkan widget Expanded untuk mengisi ruang kosong
          const Spacer(),
          // Tambahkan tombol logout di bagian bawah
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(userName ?? "Logout"),
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                print("Signed Out");
                Navigator.pushReplacementNamed(context, '/signin'); // Kembali ke SignInScreen
              });
            },
          ),
        ],
      ),
    );
  }
}
