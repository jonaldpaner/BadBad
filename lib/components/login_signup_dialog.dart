import 'package:flutter/material.dart';

class LoginSignUpDialog extends StatefulWidget {
  const LoginSignUpDialog({Key? key}) : super(key: key);

  @override
  _LoginSignUpDialogState createState() => _LoginSignUpDialogState();
}

class _LoginSignUpDialogState extends State<LoginSignUpDialog> {
  bool isLogin = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Additional signup fields if needed
  final TextEditingController confirmPasswordController = TextEditingController();

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
        // TODO: Handle login logic here
        Navigator.of(context).pop(); // close dialog
      } else {
        // TODO: Handle sign up logic here
        Navigator.of(context).pop(); // close dialog
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text(isLogin ? 'Login' : 'Sign Up')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLogin
                    ? 'Hello, again! Enter your username and password below.'
                    : 'Welcome! Enter a username and password below.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter email';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              if (!isLogin) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm password';
                    if (value != passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),


              TextButton(
                onPressed: toggleForm,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isLogin ? "Don't have an account? " : "Already have an account? ",
                        style: const TextStyle(color: Colors.black),
                      ),
                      TextSpan(
                        text: isLogin ? "Sign Up" : "Login",
                        style: const TextStyle(
                          color: Color.fromRGBO(33, 158, 188, 1), // blue color
                          fontWeight: FontWeight.bold,
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
                  minimumSize: const Size.fromHeight(40),
                ),
                child: Text(
                  isLogin ? 'Login' : 'Sign Up',
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            ],
          ),
        ),
      ),
      // Remove actions:
      // actions: [],
    );
  }
}
