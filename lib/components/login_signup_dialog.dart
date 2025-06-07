import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADDED: Firebase Auth import

class LoginSignUpDialog extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginSignUpDialog({
    Key? key,
    required this.onLogin,
  }) : super(key: key);

  @override
  _LoginSignUpDialogState createState() => _LoginSignUpDialogState();
}

class _LoginSignUpDialogState extends State<LoginSignUpDialog> {
  bool isLogin = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Additional signup field
  final TextEditingController confirmPasswordController =
  TextEditingController();

  // ADDED: Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
      _formKey.currentState?.reset();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
    });
  }

  // MODIFIED: submit method made async and includes Firebase Auth logic
  void submit() async {
    if (_formKey.currentState!.validate()) {
      // ADDED: Try-catch block for Firebase operations
      try {
        if (isLogin) {
          // Firebase Login
          await _auth.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
          // If successful, notify HomePage and close dialog
          widget.onLogin();
          Navigator.of(context).pop();
          // ADDED: Success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged in successfully!')),
          );
        } else {
          // Firebase Sign Up
          await _auth.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
          // Close dialog after successful signup
          Navigator.of(context).pop();
          // ADDED: Success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully! Please log in.')),
          );
        }
      } on FirebaseAuthException catch (e) {
        // ADDED: Specific Firebase Auth error handling
        String message = 'An error occurred. Please check your credentials.';
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided for that user.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The email address is already in use by another account.';
        } else if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        }
        // ADDED: Display error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // ADDED: General error handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double fontSize = screenWidth * 0.04; // scales with screen width
    double verticalSpacing = screenHeight * 0.015;

    return AlertDialog(
      title: Center(
        child: Text(
          isLogin ? 'Login' : 'Sign Up',
          style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.bold),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLogin
                    ? 'Hello, again! Enter your email and password below.'
                    : 'Welcome! Enter an email and password to sign up.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: verticalSpacing * 1.5),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: fontSize),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: verticalSpacing),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                style: TextStyle(fontSize: fontSize),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              if (!isLogin) ...[
                SizedBox(height: verticalSpacing),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration:
                  const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  style: TextStyle(fontSize: fontSize),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: verticalSpacing * 1.5),
              TextButton(
                onPressed: toggleForm,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isLogin
                            ? "Don't have an account? "
                            : "Already have an account? ",
                        style: TextStyle(color: Colors.black, fontSize: fontSize),
                      ),
                      TextSpan(
                        text: isLogin ? "Sign Up" : "Login",
                        style: TextStyle(
                          color: const Color.fromRGBO(33, 158, 188, 1),
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(33, 158, 188, 1),
                  minimumSize: Size(double.infinity, screenHeight * 0.05),
                ),
                child: Text(
                  isLogin ? 'Login' : 'Sign Up',
                  style: TextStyle(color: Colors.white, fontSize: fontSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}