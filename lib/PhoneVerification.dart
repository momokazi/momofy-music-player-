import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PhoneVerificationPage extends StatefulWidget {
  @override
  _PhoneVerificationPageState createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Phone Number Verification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFFE46E86),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Form(
                key: _phoneFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        // You can add additional phone number validation here if needed
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _verifyPhoneNumber,
                      child: Text(
                        'Send Verification Code',
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPhoneNumber() async {
    if (_phoneFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: _phoneNumberController.text.trim(),
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-retrieval of the SMS code succeeded, Firebase will automatically verify the code
            await FirebaseAuth.instance.signInWithCredential(credential);
            _showToast("Phone number verified successfully", Colors.green, Colors.white);
            // Navigate to the next screen or perform any other action after successful verification
          },
          verificationFailed: (FirebaseAuthException e) {
            // Handle verification failed
            _showToast("Failed to verify phone number: ${e.message}", Colors.red, Colors.white);
          },
          codeSent: (String verificationId, int? resendToken) {
            // Navigate to the screen where users can enter the verification code
            Navigator.pushReplacementNamed(
              context,
              '/enter_verification_code',
              arguments: EnterVerificationCodeArguments(
                verificationId: verificationId,
                phoneNumber: _phoneNumberController.text.trim(),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Auto-retrieval timed out, handle it here
          },
          timeout: Duration(seconds: 60),
        );
      } catch (e) {
        _showToast("An unexpected error occurred", Colors.red, Colors.white);
        print(e.toString());
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showToast(String message, Color bgColor, Color textColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: bgColor,
      textColor: textColor,
      fontSize: 16.0,
    );
  }
}

class EnterVerificationCodeArguments {
  final String verificationId;
  final String phoneNumber;

  EnterVerificationCodeArguments({
    required this.verificationId,
    required this.phoneNumber,
  });
}
