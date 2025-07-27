import 'package:attendence/core/auth/aurth_service.dart';
import 'package:attendence/core/widgets/lable_text.dart';
import 'package:attendence/core/widgets/text_widget.dart';
import 'package:attendence/user/signup/presentation/sign_up.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../student_homepage/presentation/student_dashboard.dart';
import '../../../teacher_homepage/presentation/teacher_dashboard.dart';
import '../../student_register/presentation/student_register.dart';
import '../../teacher_register/presentation/teacher_register.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _rollController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isStudent = true;
  bool _passNotVisible = true;
  String selectedRole = 'student';
  bool _isLoading = false;

  // Theme colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFF42A5F5);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);

  @override
  void dispose() {
    _emailController.dispose();
    _rollController.dispose();
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
        color: cardColor,
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
          fillColor: cardColor,
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
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorColor),
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
      backgroundColor: backgroundColor,
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
                      color: cardColor,
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
                                colors: [primaryColor, primaryLightColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 32,
                              child: Icon(
                                Icons.login,
                                size: 32,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const TextWidget(
                            text: 'Welcome Back',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 8),
                          const TextWidget(
                            text: 'Sign in to your account',
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
                      color: cardColor,
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
                                color: _isStudent ? primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      color: _isStudent ? Colors.white : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Student',
                                      color: _isStudent ? Colors.white : Colors.grey.shade600,
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
                                color: !_isStudent ? primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: !_isStudent ? Colors.white : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    TextWidget(
                                      text: 'Teacher',
                                      color: !_isStudent ? Colors.white : Colors.grey.shade600,
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

                  // Roll Number Input (for students only)
                  if (_isStudent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildInputField(
                        controller: _rollController,
                        hintText: 'Enter your university roll no.',
                        prefixIcon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Please enter roll number' : null,
                      ),
                    ),

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
                        _passNotVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter Password' : null,
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(context, (MaterialPageRoute(builder: (context)=> SignUp())));
                      HapticFeedback.lightImpact();
                    },
                    child: LabeledText(
                      label: "Don't have an account?",
                      value: "Create one.",
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
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: primaryColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : () async {
                        final isValid = _formKey.currentState?.validate() ?? false;
                        if (!isValid) return;

                        setState(() {
                          _isLoading = true;
                        });

                        final email = _emailController.text.trim();
                        final password = _passwordController.text;

                        try {
                          final credentials = await authService.value.signIn(
                            email: email,
                            password: password,
                          );
                          // Role validation
                          if (_isStudent && !email.toLowerCase().contains('.bcr')) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: TextWidget(
                                    text: 'This is not a student email',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: errorColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }

                          if (!_isStudent && email.toLowerCase().contains('.bcr')) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: TextWidget(
                                    text: 'This is not a teacher email',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: errorColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', true);
                          await prefs.setString('role', selectedRole);

                          // Save student info in Firestore
                          if (_isStudent) {
                            // Save login role
                            await prefs.setString('roll_number', _rollController.text);

                            final docRef = FirebaseFirestore.instance.collection('students').doc(_rollController.text);
                            final docSnap = await docRef.get();

                            if (docSnap.exists) {
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => StudentDashboard()),
                                );
                              }
                            } else {
                              await docRef.set({
                                'email': email,
                                'roll': _rollController.text,
                                'signIn_at': FieldValue.serverTimestamp(),
                              });
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => RegisterStudent()),
                                );
                              }
                            }
                          } else {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('teacher_id', email);

                            final docRef = FirebaseFirestore.instance.collection('teachers').doc(email);
                            final docSnap = await docRef.get();

                            if (docSnap.exists) {
                              if (mounted) {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => TeacherDashboard())
                                );
                              }
                            } else {
                              await docRef.set({
                                'email': email,
                                'signedIn_at': FieldValue.serverTimestamp(),
                              });
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TeacherRegister()),
                                );
                              }
                            }
                            _rollController.clear();
                            _emailController.clear();
                            _passwordController.clear();
                          }
                        } on FirebaseAuthException catch (e) {
                          String message = 'Login Failed, please check your internet connection and try again.';
                          print(e.code);

                          if (e.code == 'user-not-found') {
                            message = 'No user found for the provided E-mail.';
                          } else if (e.code == 'invalid-credential') {
                            message = 'Invalid E-mail or Password provided.';
                          } else if (e.code == 'invalid-email') {
                            message = 'Provided E-mail format is not valid.';
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TextWidget(
                                  text: message,
                                  color: Colors.white,
                                ),
                                backgroundColor: errorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: TextWidget(
                                  text: 'Unexpected error: ${e.toString()}\nContact support.',
                                  color: Colors.white,
                                ),
                                backgroundColor: errorColor,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
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
                            text: 'Signing In...',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ],
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          TextWidget(
                            text: 'Sign In',
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