import 'package:attendence/core/auth/aurth_service.dart';
import 'package:attendence/user/register/presentation/student_register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Homepage/teacher_dashboard.dart';

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


  @override
  void dispose() {
    _emailController.dispose();
    _rollController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Login',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isStudent = true;
                        selectedRole = 'student';
                      });
                    },
                    child: Container(
                      height: 45,
                      width: MediaQuery.of(context).size.width * 0.45,
                      decoration: BoxDecoration(
                        color: _isStudent ? Colors.black : Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'Student',
                          style: TextStyle(
                            color: _isStudent ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isStudent = false;
                        selectedRole = 'teacher';
                      });
                    },
                    child: Container(
                      height: 45,
                      width: MediaQuery.of(context).size.width * 0.45,
                      decoration: BoxDecoration(
                        color: !_isStudent ? Colors.black : Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'Teacher',
                          style: TextStyle(
                            color: !_isStudent ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your E-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter E-mail' : null,
              ),
              SizedBox(height: 20),
              if (_isStudent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _rollController,
                    decoration: InputDecoration(
                      hintText: 'Enter your university roll no.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Please enter E-mail' : null,
                  ),
                ),
              TextFormField(
                controller: _passwordController,
                obscureText: _passNotVisible,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _passNotVisible = !_passNotVisible;
                      });
                    },
                    icon: Icon(
                      _passNotVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  hintText: 'Enter Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter Password' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(180, 40),
                  backgroundColor: Colors.white,
                ),
                onPressed: () async {
                  final isValid = _formKey.currentState?.validate() ?? false;
                  if (!isValid) return;

                  try {
                    final credentials = await authService.value.signIn(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                    );
                    final email = _emailController.text.trim();

                    if (_isStudent && !email.toLowerCase().contains('.bcr')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ This is not a student email'),
                        ),
                      );
                      return;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', true);
                    await prefs.setString('role', selectedRole);

                    if (_isStudent) {
                      final docRef = FirebaseFirestore.instance
                          .collection('students')
                          .doc(_rollController.text);
                      await docRef.set({
                        'email': email,
                        'roll': _rollController.text,
                        'registered_at': FieldValue.serverTimestamp(),
                      });
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c)=>RegisterStudent()));
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherDashboard()),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Login failed: ${e.toString()}')),
                    );
                  }
                },
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
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
