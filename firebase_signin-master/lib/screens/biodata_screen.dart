import 'package:firebase_signin/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_signin/reusable_widgets/reusable_widget.dart';
import 'package:firebase_signin/utils/color_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'signin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BiodataScreen(),
    );
  }
}

class BiodataScreen extends StatefulWidget {
  const BiodataScreen({Key? key}) : super(key: key);

  @override
  _BiodataScreenState createState() => _BiodataScreenState();
}

class _BiodataScreenState extends State<BiodataScreen> {
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userNameTextController = TextEditingController();
  final FirebaseFirestore firebase = FirebaseFirestore.instance;
  late CollectionReference biodata;
  Uint8List? _webImage; // For handling web images
  File? _image; // For mobile image handling

  // Function to pick image based on platform
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      // For web
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      }
    } else {
      // For mobile
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  // Function to upload image to Firebase Storage
  Future<String?> _uploadImage(File? imageFile, Uint8List? webImage) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child("images/$fileName");

      if (kIsWeb) {
        // Upload image for web using Uint8List
        UploadTask uploadTask = ref.putData(webImage!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        // Upload image for mobile using File
        UploadTask uploadTask = ref.putFile(imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // Function to save biodata and image URL to Firestore
  Future<void> _saveData(String name, String className, String imageUrl) async {
    try {
      // Ensure the user provided data
      if (name.isEmpty || className.isEmpty) {
        print("Name or class is empty. Please fill both fields.");
        return;
      }

      CollectionReference users =
          FirebaseFirestore.instance.collection('biodata');
      await users.add({
        'nama': name,
        'kelas': className,
        'imageUrl': imageUrl, // Include image URL in the data
      });
      print("Data saved successfully.");
    } catch (e) {
      print("Error saving data: $e");
    }
  }

  // Function to handle submit data
  void _submitData() async {
    // Validate if user has selected an image
    if (_image != null || _webImage != null) {
      // Upload image to Firebase Storage
      String? imageUrl = await _uploadImage(_image, _webImage);
      if (imageUrl != null) {
        // Save biodata to Firestore
        await _saveData(
          _userNameTextController.text,
          _emailTextController.text,
          imageUrl,
        );
        print("Data successfully saved!");

        // Navigate to SignInScreen after saving data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
        );
      } else {
        print("Image upload failed");
      }
    } else {
      print("Please select an image");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "BIODATA",
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
            padding: EdgeInsets.fromLTRB(20, 80, 20, 0),
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(0, 158, 158, 158)
                              .withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _webImage == null && _image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image,
                                  color: Colors.grey[600], size: 50),
                              SizedBox(height: 10),
                              Text(
                                'Upload Image',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          )
                        : _webImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners for image
                                child: Image.memory(
                                  _webImage!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    15), // Rounded corners for image
                                child: Image.file(
                                  _image!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                  ),
                ),
                const SizedBox(height: 40), // Space after image picker
                reusableTextField(
                  "Enter Name",
                  Icons.person_outline,
                  false,
                  _userNameTextController,
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  "Enter Class",
                  Icons.person_outline,
                  false,
                  _emailTextController,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save,
                          size: 20, color: Colors.white), // Icon in button
                      SizedBox(width: 10), // Space between icon and text
                      Text(
                        "Save Biodata",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
