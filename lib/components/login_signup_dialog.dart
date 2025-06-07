import 'package:flutter/material.dart';

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

  void submit() {
    if (_formKey.currentState!.validate()) {
      if (isLogin) {
        // When logging in, invoke the callback to notify HomePage
        widget.onLogin();
        Navigator.of(context).pop();
      } else {
        // TODO: Handle sign-up logic here if needed
        Navigator.of(context).pop();
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
