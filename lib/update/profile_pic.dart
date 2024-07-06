import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UpdateProfilePicPage extends StatefulWidget {
  @override
  _UpdateProfilePicPageState createState() => _UpdateProfilePicPageState();
}

class _UpdateProfilePicPageState extends State<UpdateProfilePicPage> {
  bool _isLoading = false;
  File? _imageFile;
  String? _currentImageUrl;
  String? _documentId;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentImageUrl();
  }

  Future<void> _loadCurrentImageUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        setState(() {
          _currentImageUrl = doc.data()['imageUrl'];
          _documentId = doc.id;
        });
        print(_currentImageUrl);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _imageFile = File(pickedFile.path);
        }
      });
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _updateProfilePic() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _imageFile != null && _documentId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final fileName = '${user.uid}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child('user_images').child(fileName);
        await storageRef.putFile(_imageFile!);

        final downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(_documentId).update({
          'imageUrl': downloadUrl,
        });

        setState(() {
          _currentImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile Picture'),
        backgroundColor: Color(0xFFE46E86),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _imageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(75.0),
                        child: Image.file(
                          _imageFile!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      )
                          : (_currentImageUrl != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(75.0),
                        child: Image.network(
                          _currentImageUrl!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      )
                          : CircleAvatar(
                        radius: 75,
                        child: Icon(
                          Icons.person,
                          size: 75,
                        ),
                      )),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text(
                          'Choose Image',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE46E86),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          minimumSize: Size(double.infinity, 50),
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateProfilePic,
                        child: Text(
                          'Update Profile Picture',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE46E86),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          minimumSize: Size(double.infinity, 50),
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                SizedBox(
                  height: 20,
                ),
              if (_isLoading)
                CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
