import 'dart:convert';

import 'package:attendence/settings/student_profile/data/student_profile_datasource.dart';
import 'package:attendence/user/register/data/student_model.dart';
import 'package:attendence/user/register/presentation/student_register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/student_profile/presentation/student_profile.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final fbStore = FirebaseFirestore.instance.collection('subjects');
  final fbStudent = FirebaseFirestore.instance.collection('students');
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  StudentModel? studentData;
  bool _isLoading = false;
  bool _attendanceMarked = false;

  @override
  void initState() {
    super.initState();
    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    final roll = await _loadRollFromPref();
    if (roll == null) return;

    final doc = await StudentProfileDatasource().getStudentData(roll);
    if (doc != null) {
      setState(() {
        studentData = doc;
      });
    }
  }

  Future<String?> _loadRollFromPref() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRoll = prefs.getString('roll_number');
    return savedRoll;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Function to mark attendance via HTTP request to Google Apps Script
  Future<void> markAttendance({String value = "1"}) async {
    final pref = await SharedPreferences.getInstance();
    final roll = await pref.getString('roll');

    if (roll == null) return;

    final date = DateFormat('dd-MMM-yyyy').format(DateTime.now());

    const url =
        'https://script.google.com/macros/s/AKfycby__0vVPO3DxpV5dUXgwD3IMaqNowsxsjFIrJ87wDVw_5pr6qQ6DaVb-6DNfAFaQM0c/exec';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'rollNumber': roll, 'date': date, 'value': value}),
    );

    if (response.statusCode == 200) {
      print('✅ Attendance Marked: $roll, $date, $value');
    } else {
      print('❌ Attendance Failed: $roll, $date, $value');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (studentData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          iconSize: 28,
          style: IconButton.styleFrom(backgroundColor: Colors.grey.shade200),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => RegisterStudent()),
            );
          },
          icon: Icon(Icons.person),
        ),
        title: Text(
          'Welcome ${studentData!.firstName}',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Lectures', style: TextStyle(fontSize: 22)),
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
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(title: Text('Loading...'));
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const ListTile(
                            title: Text('⚠️ Attendance info not found.'),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final isOpen = data['isOpen'] == true;
                        final codeFromFirestore = data['code'];

                        return ExpansionTile(
                          title: const Text('Computer Architecture',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                          children: [
                            isOpen
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'MARK ATTENDANCE FOR: ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Name: ${studentData!.firstName} ${studentData!.lastName} ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Roll Number: ${studentData!.rollNumber} ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      TextFormField(
                                        controller: _codeController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        decoration: InputDecoration(
                                          hintText: 'Enter attendance code',
                                          counterText: "",
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.black,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.black,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
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
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.5,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          onPressed:
                                              (_isLoading || _attendanceMarked)
                                              ? null
                                              : () async {
                                                  final isValid =
                                                      _formKey.currentState
                                                          ?.validate() ??
                                                      false;
                                                  if (!isValid) return;

                                                  setState(
                                                    () => _isLoading = true,
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).hideCurrentSnackBar();

                                                  try {
                                                    if (codeFromFirestore ==
                                                        null) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            '❌ Code not available or expired',
                                                          ),
                                                        ),
                                                      );
                                                      setState(
                                                        () =>
                                                            _isLoading = false,
                                                      );
                                                      return;
                                                    }

                                                    if (_codeController.text
                                                            .trim() !=
                                                        codeFromFirestore
                                                            .toString()) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            '❌ Incorrect code',
                                                          ),
                                                        ),
                                                      );
                                                      setState(
                                                        () =>
                                                            _isLoading = false,
                                                      );
                                                      return;
                                                    }

                                                    await markAttendance();

                                                    setState(() {
                                                      _attendanceMarked = true;
                                                      _isLoading = false;
                                                    });

                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '✅ Attendance marked successfully',
                                                        ),
                                                      ),
                                                    );

                                                    _codeController.clear();
                                                  } catch (e) {
                                                    print(
                                                      '❌ Error marking attendance: $e',
                                                    );
                                                    setState(
                                                      () => _isLoading = false,
                                                    );

                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '❌ Error occurred',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Text(
                                                  _attendanceMarked
                                                      ? 'Marked'
                                                      : 'Mark Present',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                    ],
                                  )
                                : const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Attendance not open',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
