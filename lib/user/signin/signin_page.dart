import 'package:attendence/Homepage/student_dashboard.dart';
import 'package:attendence/core/auth/aurth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Homepage/teacher_dashboard.dart';
import '../student_register/presentation/student_register.dart';
import '../teacher_register/presentation/teacher_register.dart';

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

                  final email = _emailController.text.trim();
                  final password = _passwordController.text;

                  try {
                    final credentials = await authService.value.signIn(
                      email: email,
                      password: password,
                    );

                    // Role validation
                    if (_isStudent && !email.toLowerCase().contains('.bcr')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ This is not a student email')),
                      );
                      return;
                    }

                    if (!_isStudent && email.toLowerCase().contains('.bcr')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ This is not a teacher email')),
                      );
                      return;
                    }

                    // Save login role
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', true);
                    await prefs.setString('role', selectedRole);
                    await prefs.setString('roll_number', _rollController.text);

                    // Save student info in Firestore
                    if (_isStudent) {
                      final docRef = FirebaseFirestore.instance
                          .collection('students')
                          .doc(_rollController.text);

                      final docSnap = await docRef.get();

                      if(docSnap.exists){
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => StudentDashboard()),
                        );
                      } else{
                        await docRef.set({
                          'email': email,
                          'roll': _rollController.text,
                          'registered_at': FieldValue.serverTimestamp(),
                        });
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterStudent()),
                        );
                      }
                    } else {
                      final docRef = FirebaseFirestore.instance.collection('teachers').doc(email);

                      final docSnap = await docRef.get();

                      if(docSnap.exists){
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder:
                                (_) => TeacherDashboard())
                        );
                      } else {
                        await docRef.set(
                            {
                              'email': email,
                              'registered_at': FieldValue.serverTimestamp(),
                            });
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherRegister()),
                        );
                      }
                      _rollController.clear();
                      _emailController.clear();
                      _passwordController.clear();

                    }}on FirebaseAuthException catch (e) {
                    String message = '❌ Login failed';

                    if (e.code == 'user-not-found') {
                      message = '❌ No user found for that email';
                    } else if (e.code == 'wrong-password') {
                      message = '❌ Wrong password provided';
                    } else if (e.code == 'invalid-email') {
                      message = '❌ Invalid email format';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );

                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Unexpected error: ${e.toString()}')),
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
