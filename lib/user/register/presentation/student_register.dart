import 'package:attendence/Homepage/student_dashboard.dart';
import 'package:attendence/user/register/data/register_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterStudent extends StatefulWidget {
  const RegisterStudent({super.key});

  @override
  State<RegisterStudent> createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  final RegisterStudentService _studentService = RegisterStudentService();

  final _formKey = GlobalKey<FormState>();
  final List<String> _sections = ['A', 'B', 'C', 'D'];
  final List<String> _courses = ['BCA', 'PGDM', 'MCA'];
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _rollNoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  String? _selectedSection;
  String? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = FirebaseAuth.instance.currentUser!.email!;
  }

  @override
  void dispose() {
    _rollNoCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Setup Profile', style: TextStyle()),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _rollNoCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter Roll No.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select course',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        value: _selectedCourse,
                        items: _courses
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s,
                                child: Text(s),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCourse = value),
                        validator: (v) =>
                            v == null ? 'Please select a course' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select section',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        value: _selectedSection,
                        items: _sections
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s,
                                child: Text(s),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedSection = value),
                        validator: (v) =>
                            v == null ? 'Please select a section' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextFormField(
                  style: TextStyle(color: Colors.grey),
                  readOnly: true,
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
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

                    final registered = await _studentService.registerStudents(
                      email: _emailCtrl.text,
                      name: _nameCtrl.text,
                      roll: _rollNoCtrl.text,
                      course: _selectedCourse.toString(),
                      section: _selectedSection.toString(),
                    );

                    if (registered) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Student registered successfully'),
                        ),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentDashboard(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Roll number already registered'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Submit',
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
      ),
    );
  }
}
