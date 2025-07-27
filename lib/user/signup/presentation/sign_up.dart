import 'package:attendence/core/auth/aurth_service.dart';
import 'package:attendence/core/widgets/lable_text.dart';
import 'package:attendence/core/widgets/text_widget.dart';
import 'package:attendence/user/signin/presentaton/signin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_colors.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isStudent = true;
  bool _passNotVisible = true;
  String selectedRole = 'student';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.grey.shade600)
              : null,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 32,
                              child: Icon(
                                Icons.app_registration,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const TextWidget(
                            text: 'Welcome',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 8),
                          const TextWidget(
                            text: 'Create your new account',
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Role Selection
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isStudent = true;
                                selectedRole = 'student';
                              });
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _isStudent
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      color: _isStudent
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Student',
                                      color: _isStudent
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isStudent = false;
                                selectedRole = 'teacher';
                              });
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: !_isStudent
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: !_isStudent
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Teacher',
                                      color: !_isStudent
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email Input
                  _buildInputField(
                    controller: _emailController,
                    hintText: 'Enter your E-mail',
                    prefixIcon: Icons.email_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Please enter E-mail' : null,
                  ),

                  const SizedBox(height: 20),

                  // Password Input
                  _buildInputField(
                    controller: _passwordController,
                    hintText: 'Enter Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _passNotVisible,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _passNotVisible = !_passNotVisible;
                        });
                      },
                      icon: Icon(
                        _passNotVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Please enter Password' : null,
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SignInPage()),
                      );
                      HapticFeedback.lightImpact();
                    },
                    child: LabeledText(
                      label: "Already have an account?",
                      value: "SignIn.",
                      labelFontSize: 14,
                      labelWeight: FontWeight.normal,
                      labelColor: Colors.black87,
                      valueColor: Colors.blue,
                      valueFontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final isValid =
                                  _formKey.currentState?.validate() ?? false;
                              if (!isValid) return;

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              );

                              try {
                                final UserCredential? userCredential =
                                    await AuthService().signUp(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );

                                if (userCredential != null &&
                                    userCredential.user != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.success,
                                      content: TextWidget(
                                        color: Colors.white,
                                        text:
                                            'Registration Successful! Welcome ${userCredential.user!.email}',
                                      ),
                                    ),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SignInPage(),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: AppColors.error,
                                      content: TextWidget(
                                        text:
                                            'Registration failed. Please try again.',
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                Navigator.of(context).pop(); // Close Loading

                                String errorMessage;
                                switch (e.code) {
                                  case 'email-already-in-use':
                                    errorMessage =
                                        'This email is already registered.';
                                    break;
                                  case 'invalid-email':
                                    errorMessage =
                                        'The email address is invalid.';
                                    break;
                                  case 'weak-password':
                                    errorMessage =
                                        'Password should be at least 6 characters.';
                                    break;
                                  default:
                                    errorMessage =
                                        'An error occurred. (${e.code})';
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.error,
                                    content: TextWidget(
                                      text: errorMessage,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                Navigator.of(context).pop(); // Close Loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.error,
                                    content: TextWidget(
                                      text:
                                          'AN unexpected error occurred: ${e.toString()}',
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                            },
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const TextWidget(
                                  text: 'Signing Up...',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.app_registration,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                TextWidget(
                                  text: 'Sign Up',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
