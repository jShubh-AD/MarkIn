import 'package:attendence/settings/student_profile/data/student_profile_datasource.dart';
import 'package:attendence/subject/data/subject_model.dart';
import 'package:attendence/user/register/data/student_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/aurth_service.dart';
import '../../../core/widgets/lable_text.dart';
import '../../../core/widgets/text_widget.dart';
import '../../../user/signin/signin_page.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  final _formKey = GlobalKey<FormState>();
  StudentModel? studentData;
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudentDetails();
  }

  Future<void> _loadStudentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final roll = await _loadRollFromPrefs();
      if (roll == null || roll.isEmpty) {
        throw Exception("Roll number not found in preferences.");
      }

      final doc = await StudentProfileDatasource().getStudentData(roll);
      if (doc != null) {
        setState(() {
          studentData = doc;
        });
      } else {
        throw Exception("Student data not found for roll number: $roll");
      }

      final subjects = await StudentProfileDatasource().getStudentSubjects(roll: roll);
      setState(() {
        _subjects = subjects;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load profile data: ${e.toString()}";
      });
      // Optionally show a SnackBar or AlertDialog for the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? "An unknown error occurred")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _loadRollFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('roll_number');
    } catch (e) {
      throw Exception("Failed to load roll number from preferences: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 50),
              SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadStudentDetails,
                icon: Icon(Icons.refresh),
                label: Text("Retry"),
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          radius: 35,
                          child: Icon(Icons.person, size: 35, color: Colors.deepPurple),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${studentData!.firstName} ${studentData!.lastName}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Course: ${studentData!.course} | Section: ${studentData!.section}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Roll No: ${studentData!.rollNumber}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Email: ${studentData!.email}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                TextWidget(
                  text: 'Semester Subjects',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                const SizedBox(height: 10),
                _subjects.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No subjects found for this student.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return Card(
                      elevation: 4,
                      color: Colors.blueGrey.shade50,
                      shadowColor: Colors.blueGrey.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabeledText(
                              label: 'Subject: ',
                              value: subject.subjectName,
                              labelWeight: FontWeight.w700,
                              valueColor: Colors.black87,
                              labelFontSize: 16,
                              valueFontSize: 16,
                            ),
                            const SizedBox(height: 4),
                            LabeledText(
                              label: 'Teacher: ',
                              value: subject.subjectTeacher,
                              labelWeight: FontWeight.w600,
                              labelFontSize: 14,
                              valueFontSize: 14,
                              valueColor: Colors.grey[700],
                            ),
                            const SizedBox(height: 4),
                            LabeledText(
                              label: 'Code: ',
                              value: subject.subjectCode,
                              labelWeight: FontWeight.w600,
                              labelFontSize: 14,
                              valueFontSize: 14,
                              valueColor: Colors.grey[700],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Change Password Card
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 6,
                  shadowColor: Colors.black.withOpacity(0.9),
                  child: InkWell(
                    onTap: () {
                      // TODO: Add change password logic (e.g., navigate to a new page)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Change Password functionality not yet implemented.")),
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Row(
                        children: const [
                          Icon(Icons.lock_outline, color: Colors.black, size: 24),
                          SizedBox(width: 15),
                          Text(
                            'Change Password',
                            style: TextStyle(fontSize: 17, color: Colors.black87),
                          ),
                          Spacer(),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Logout Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () async {
                    try {
                      await authService.value.logOut();
                      // Clear shared preferences upon successful logout
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear(); // Clears all saved data, including roll_number
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInPage()),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error logging out: ${e.toString()}")),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Add some bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}