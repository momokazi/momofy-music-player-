import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google.dart'; // Ensure this file exists and contains the `AuthMethods` class
import 'forget.dart';
import 'home_page.dart';
import 'signup_page.dart';

final auth = FirebaseAuth.instance;

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthMethods _auth = AuthMethods();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RegExp emailRegExp = RegExp(
    r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

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

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (_rememberMe) {
          // Save email and password to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('email', _emailController.text.trim());
          prefs.setString('password', _passwordController.text.trim());
        } else {
          // Clear email and password from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          prefs.remove('email');
          prefs.remove('password');
        }
        _showToast("Login successful!", const Color(0xFF86E4D5),
            Colors.black); // Use contrasting color for success toast
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      } on FirebaseAuthException catch (e) {
        _showToast(e.message ?? "An error occurred", const Color(0xFFE4C686),
            Colors.black87); // Use contrasting color for error toast
      } catch (e) {
        _showToast(e.toString(), const Color(0xFFE4C686),
            Colors.black87); // Use contrasting color for generic error toast
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Momofy', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE46E86),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto', // Example font
                  ),
                ),
                const SizedBox(height: 32), // Increase spacing
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email), // Add icon
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!emailRegExp.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock), // Add icon
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('Remember Me'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordPage()),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE46E86),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    color: Colors.white,
                    thickness: 1.0,
                  ),
                ),
                const Text(
                  "Login with",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                    height: 16), // Add spacing between text and buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () async {
                        bool res = await _auth.signInWithGoogle(context);
                        if (res) {
                          Navigator.pushNamed(context, '/homeScreen');
                        }
                      },
                      icon: Image.asset(
                        'Assets/images/google.png', // Ensure the correct path
                        height: 40,
                        width: 40,
                      ),
                      iconSize: 48, // Adjust the size as needed
                      padding: const EdgeInsets.all(0), // Remove padding
                      constraints: const BoxConstraints(), // Remove constraints
                    ),
                    const SizedBox(
                        width: 8), // Add spacing between icon and text
                    const Text(
                      "Google SignIn",
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            Colors.white, // Ensure the text color is consistent
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    color: Colors.white,
                    thickness: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => SignupPage(),
                        transitionsBuilder: (_, animation, __, child) {
                          return Stack(
                            children: [
                              FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              SlideTransition(
                                position: Tween(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                  child: const Hero(
                    tag: 'signupButton',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        "Create an Account? Sign Up",
                        style: TextStyle(
                          color: Colors
                              .white, // Use contrast color for signup button text
                        ),
                      ),
                    ),
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
