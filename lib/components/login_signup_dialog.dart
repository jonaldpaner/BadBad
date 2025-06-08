import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool isLoading = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
      _formKey.currentState?.reset();
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      passwordVisible = false;
      confirmPasswordVisible = false;
    });
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        widget.onLogin();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!')),
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully! Please log in.')),
        );
      }
    } on FirebaseAuthException catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogBackground = theme.dialogBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final buttonColor = theme.colorScheme.primary;

    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);
    const baseFontSize = 16.0;
    final scale = screenWidth / 375;
    final clampedScale = scale.clamp(0.8, 1.2);

    final titleFontSize = (baseFontSize + 6) * clampedScale * textScaleFactor;
    final bodyFontSize = (baseFontSize - 2) * clampedScale * textScaleFactor;
    final toggleFontSize = (baseFontSize - 4) * clampedScale * textScaleFactor;

    final screenHeight = MediaQuery.of(context).size.height;
    final verticalSpacing = screenHeight * 0.015;

    return AlertDialog(
      backgroundColor: dialogBackground,
      title: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isLogin ? 'Login' : 'Sign Up',
            key: ValueKey<bool>(isLogin),
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
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
                  color: textColor.withOpacity(0.7),
                  fontSize: bodyFontSize,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: verticalSpacing * 1.5),
              TextFormField(
                controller: emailController,
                focusNode: emailFocus,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: textColor.withOpacity(0.4)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: buttonColor),
                  ),
                ),
                style: TextStyle(fontSize: bodyFontSize, color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(passwordFocus);
                },
              ),
              SizedBox(height: verticalSpacing),
              TextFormField(
                controller: passwordController,
                focusNode: passwordFocus,
                obscureText: !passwordVisible,
                textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: textColor.withOpacity(0.4)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: buttonColor),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: textColor.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        passwordVisible = !passwordVisible;
                      });
                    },
                    tooltip: passwordVisible ? 'Hide password' : 'Show password',
                  ),
                ),
                style: TextStyle(fontSize: bodyFontSize, color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (isLogin) {
                    submit();
                  } else {
                    FocusScope.of(context).requestFocus(confirmPasswordFocus);
                  }
                },
              ),
              if (!isLogin) ...[
                SizedBox(height: verticalSpacing),
                TextFormField(
                  controller: confirmPasswordController,
                  focusNode: confirmPasswordFocus,
                  obscureText: !confirmPasswordVisible,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textColor.withOpacity(0.4)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: buttonColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: textColor.withOpacity(0.6),
                      ),
                      onPressed: () {
                        setState(() {
                          confirmPasswordVisible = !confirmPasswordVisible;
                        });
                      },
                      tooltip: confirmPasswordVisible ? 'Hide password' : 'Show password',
                    ),
                  ),
                  style: TextStyle(fontSize: bodyFontSize, color: textColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => submit(),
                ),
              ],
              SizedBox(height: verticalSpacing * 1.5),
              TextButton(
                onPressed: isLoading ? null : toggleForm,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: isLogin
                            ? "Don't have an account? "
                            : "Already have an account? ",
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: toggleFontSize),
                      ),
                      TextSpan(
                        text: isLogin ? "Sign Up" : "Login",
                        style: TextStyle(
                          color: const Color(0xFF219EBC),
                          fontWeight: FontWeight.bold,
                          fontSize: toggleFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.05,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF219EBC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    isLogin ? 'Login' : 'Sign Up',
                    style: TextStyle(color: Colors.white, fontSize: bodyFontSize),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
