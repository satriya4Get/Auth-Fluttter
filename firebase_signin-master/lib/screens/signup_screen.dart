import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_signin/reusable_widgets/reusable_widget.dart';
import 'package:firebase_signin/screens/biodata_screen.dart';
import 'package:firebase_signin/utils/color_utils.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key, this.id}) : super(key: key);
  final String? id;

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();
  final FirebaseFirestore firebase = FirebaseFirestore.instance;
  late CollectionReference signup;

  @override
  void initState() {
    super.initState();
    signup = firebase.collection('signup');
    getData();
  }

  void getData() async {
    if (widget.id != null) {
      var data = await signup.doc(widget.id).get();
      if (data.exists && data.data() != null) {
        var item = data.data() as Map<String, dynamic>;
        setState(() {
          _passwordTextController.text = item['password'] ?? '';
          _emailTextController.text = item['email_id'] ?? '';
          _userNameTextController.text = item['username'] ?? '';
        });
      } else {
        print("Data not found for id: ${widget.id}");
      }
    }
  }

  @override
  void dispose() {
    _passwordTextController.dispose();
    _emailTextController.dispose();
    _userNameTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("4FC3F7"),
              hexStringToColor("0288D1"),
              hexStringToColor("01579B"),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  logoWidget("assets/images/logo1.png"),
                  const SizedBox(height: 20),
                  reusableTextField("Enter Username", Icons.person_outline,
                      false, _userNameTextController),
                  const SizedBox(height: 20),
                  reusableTextField("Enter Email Id", Icons.email, false,
                      _emailTextController),
                  const SizedBox(height: 20),
                  reusableTextField("Enter Password", Icons.lock_outlined, true,
                      _passwordTextController),
                  const SizedBox(height: 20),
                  firebaseUIButton(context, "Sign Up", () async {
                    if (_formKey.currentState!.validate()) {
                      String email = _emailTextController.text.trim();
                      String password = _passwordTextController.text.trim();
                      String username = _userNameTextController.text.trim();

                      if (email.isNotEmpty &&
                          password.isNotEmpty &&
                          username.isNotEmpty) {
                        try {
                          UserCredential userCredential = await FirebaseAuth
                              .instance
                              .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                          await signup.doc(userCredential.user?.uid).set({
                            'username': username,
                            'email_id': email,
                            'password': password,
                          });
                          print("User registered and data stored in Firebase");
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BiodataScreen()));
                        } catch (e) {
                          print("Error: $e");
                        }
                      } else {
                        print("Please fill in all fields.");
                      }
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
