import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'update/profile_pic.dart';
import 'update/updatepassword.dart';

class UpdateAccountInfoPage extends StatefulWidget {
  @override
  _UpdateAccountInfoPageState createState() => _UpdateAccountInfoPageState();
}

class _UpdateAccountInfoPageState extends State<UpdateAccountInfoPage> {
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  User? _currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Map<String, dynamic>? userData = await _getUserData(user.email!);
      setState(() {
        _currentUser = user;
        _userData = userData;
        _nameController.text = _userData?['name'] ?? '';
      });
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  Future<void> _updateUser(DocumentSnapshot doc) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(doc.id).update({
        'name': _nameController.text.trim(),
      });
      print("User Updated");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated successfully')),
      );
    } catch (error) {
      print("Failed to update user: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: $error')),
      );
    }
  }

  Future<void> _fetchAndUpdateUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          await _updateUser(doc);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User document not found')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPasswordUpdate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdatePasswordPage()),
    );
  }

  void _navigateToProfilePicUpdate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateProfilePicPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Account Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFFE46E86),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE46E86),
        ),
      )
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _userData?['imageUrl'] != null &&
                          (_userData!['imageUrl'] as String).isNotEmpty
                          ? NetworkImage(_userData!['imageUrl'] as String)
                          : AssetImage('assets/profile_placeholder.png')
                      as ImageProvider,
                    ),
                    TextButton(
                      onPressed: _navigateToProfilePicUpdate,
                      child: Text(
                        'Update Profile Picture',
                        style: TextStyle(
                          color: Color(0xFFE46E86),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Name',
                style: TextStyle(
                  color: Color(0xFFE46E86),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF2B2D30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Enter your name',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchAndUpdateUser,
                child: Text(
                  'Update Info',
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
                onPressed: _navigateToPasswordUpdate,
                child: Text(
                  'Change Password',
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
    );
  }
}
