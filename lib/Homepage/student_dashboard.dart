import 'dart:convert';
import 'package:attendence/core/auth/aurth_service.dart';
import 'package:attendence/user/signin/signin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final fbStore = FirebaseFirestore.instance.collection('subjects');
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _attendanceMarked = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Function to mark attendance via HTTP request to Google Apps Script
  Future<void> markAttendance({String value = "1"}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email!;
    final date = DateFormat('dd-MMM-yyyy').format(DateTime.now());

    const url =
        'https://script.google.com/macros/s/AKfycbwv7jh3NpU7zGd-p3qBvmnz7pQw4v_sTmBtcZDBljdloV73Hxx4yQXZY5LWD0g7AE8J/exec';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'date': date, 'value': value}),
    );

    if (response.statusCode == 200) {
      print('✅ Attendance Marked: $email, $date, $value');
    } else {
      print('❌ Attendance Failed: $email, $date, $value');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Mark Attendance'),
        actions: [
          GestureDetector(
            onTap: () {
              authService.value.logOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInPage()),
              );
            },
            child: const Icon(Icons.logout),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Lectures',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: fbStore
                          .doc('computer_arc')
                          .collection('computer_arc_sec_d')
                          .doc('attendance_open')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(title: Text('Loading...'));
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const ListTile(
                            title: Text('⚠️ Attendance info not found.'),
                          );
                        }

                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        final isOpen = data['isOpen'] == true;
                        final codeFromFirestore = data['code'];

                        return ExpansionTile(
                          title: const Text('Computer Architecture'),
                          children: [
                            isOpen
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                TextFormField(
                                  controller: _codeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    hintText: 'Enter attendance code',
                                    counterText: "",
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.black),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.black),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.red),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Enter attendance code';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width*0.5,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onPressed: (_isLoading || _attendanceMarked)
                                        ? null
                                        : () async {
                                      final isValid =
                                          _formKey.currentState?.validate() ?? false;
                                      if (!isValid) return;

                                      setState(() => _isLoading = true);
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                                      try {
                                        if (codeFromFirestore == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('❌ Code not available or expired'),
                                            ),
                                          );
                                          setState(() => _isLoading = false);
                                          return;
                                        }

                                        if (_codeController.text.trim() !=
                                            codeFromFirestore.toString()) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('❌ Incorrect code'),
                                            ),
                                          );
                                          setState(() => _isLoading = false);
                                          return;
                                        }

                                        await markAttendance();

                                        setState(() {
                                          _attendanceMarked = true;
                                          _isLoading = false;
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ Attendance marked successfully'),
                                          ),
                                        );

                                        _codeController.clear();
                                      } catch (e) {
                                        print('❌ Error marking attendance: $e');
                                        setState(() => _isLoading = false);

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('❌ Error occurred'),
                                          ),
                                        );
                                      }
                                    },
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : Text(
                                      _attendanceMarked ? 'Marked' : 'Mark Present',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10)
                              ],
                            )
                                : const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Not taking attendance currently',
                                style: TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
