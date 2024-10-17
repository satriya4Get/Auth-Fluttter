import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  dynamic _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _editingItemId;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/signin');
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      var imageFile = await ImagePickerWeb.getImageAsBytes();
      if (imageFile != null) {
        setState(() {
          _image = imageFile;
        });
      }
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _saveData() async {
    if (_nameController.text.isEmpty || (_image == null && _editingItemId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide both name and image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = '';

      if (_image != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('items/$fileName');

        if (kIsWeb && _image is Uint8List) {
          UploadTask uploadTask = storageRef.putData(_image);
          TaskSnapshot snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        } else if (_image is File) {
          UploadTask uploadTask = storageRef.putFile(_image);
          TaskSnapshot snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        }
      }

      if (_editingItemId == null) {
        await FirebaseFirestore.instance.collection('items').add({
          'name': _nameController.text,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added successfully')));
      } else {
        Map<String, dynamic> updatedData = {
          'name': _nameController.text,
        };

        if (imageUrl.isNotEmpty) {
          updatedData['imageUrl'] = imageUrl;
        }

        await FirebaseFirestore.instance.collection('items').doc(_editingItemId).update(updatedData);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated successfully')));
      }

      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _nameController.clear();
    setState(() {
      _image = null;
      _editingItemId = null;
    });
  }

  void _editItem(String id, String name, String imageUrl) {
    _nameController.text = name;
    setState(() {
      _editingItemId = id;
      _image = null;
    });
    _showFormModal();
  }

  Future<void> _deleteItem(String id, String imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(id).delete();
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete item: $e')));
    }
  }

  Stream<QuerySnapshot> _fetchItems() {
    return FirebaseFirestore.instance.collection('items').orderBy('createdAt').snapshots();
  }

  Future<void> _showFormModal() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_editingItemId == null ? 'Add Item' : 'Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Image'),
                ),
                const SizedBox(height: 10),
                _image == null
                    ? const Text('No image selected.')
                    : kIsWeb && _image is Uint8List
                        ? Image.memory(_image, height: 150)
                        : _image is File
                            ? Image.file(_image, height: 150)
                            : const SizedBox.shrink(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveData();
                Navigator.of(context).pop();
              },
              child: Text(_editingItemId == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1D3557),
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF457B9D)),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFE63946)),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF457B9D),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _showFormModal,
              child: const Text('Tambahkan Data'),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _fetchItems(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data!.docs;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Image')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: items.map((item) {
                          final data = item.data() as Map<String, dynamic>;
                          return DataRow(
                            cells: [
                              DataCell(Text(data['name'], style: const TextStyle(fontSize: 14))),
                              DataCell(
                                data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                                    ? Image.network(
                                        data['imageUrl'],
                                        height: 50,
                                      )
                                    : const Text('No image available'),
                              ),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF457B9D)),
                                    onPressed: () => _editItem(item.id, data['name'], data['imageUrl']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Color(0xFFE63946)),
                                    onPressed: () => _deleteItem(item.id, data['imageUrl']),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
