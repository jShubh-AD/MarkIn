import 'dart:convert';

import 'package:attendence/Homepage/data/students_data/attendance_overview_model.dart';
import 'package:attendence/settings/student_profile/data/student_profile_datasource.dart';
import 'package:attendence/subject/data/subject_model.dart'; // Import SubjectModel
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/lable_text.dart'; // Ensure LabeledText is available
import '../../../core/widgets/text_widget.dart'; // Ensure TextWidget is available
import '../settings/student_profile/presentation/student_profile.dart';
import '../user/student_register/data/student_model.dart';
import '../user/student_register/presentation/student_register.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  StudentModel? studentData;
  List<SubjectModel> _studentSubjects = [];
  bool _isLoadingDashboard = true;
  bool _isMarkingAttendance = false;
  String? _dashboardErrorMessage;
  String? _markedSubjectCode;
  bool isMarked = false;

  // Define your primary color here for easy access
  static const Color _primaryBlue = Color(0xFF1E88E5); // Material Blue 600

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardErrorMessage = null;
    });
    try {
      final roll = await _loadRollFromPref();
      if (roll == null || roll.isEmpty) {
        throw Exception(
          "Roll number not found. Please register.",
        );
      }

      final studentDoc = await StudentProfileDatasource().getStudentData(roll);
      if (studentDoc == null) {
        throw Exception(
          "Student data not found for roll number: $roll. Please complete registration.",
        );
      }

      final subjects = await StudentProfileDatasource().getStudentSubjects(
        roll: roll,
      );

      setState(() {
        studentData = studentDoc;
        _studentSubjects = subjects;
      });
    } catch (e) {
      setState(() {
        _dashboardErrorMessage =
            "Failed to load dashboard data: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(text:
            _dashboardErrorMessage ??
                "An unknown error occurred loading data contact support.",
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }

  Future<String?> _loadRollFromPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('roll_number');
    } catch (e) {
      throw Exception("Failed to access local storage for roll number.");
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Function to mark attendance via HTTP request to Google Apps Script
  /// This logic remains unchanged as per requirements.
  /*Future<bool> markAttendance({
    required String rollNumber,
    required String subjectCode,
    required String sectionId,
    required String sessionId,
    required String submittedCode,
  }) async {
    final pref = await SharedPreferences.getInstance();
    final roll = pref.getString(
      'roll_number',
    ); // Use 'roll_number' consistently

    if (roll == null || roll != rollNumber) {
      print('❌ Roll mismatch or not found in prefs.');
      return false;
    }

    final date = DateFormat('dd-MMM-yyyy').format(DateTime.now());
    const url =
        'https://script.google.com/macros/s/AKfycby__0vVPO3DxpV5dUXgwD3IMaqNowsxsjFIrJ87wDVw_5pr6qQ6DaVb-6DNfAFaQM0c/exec';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'rollNumber': roll,
        'date': date,
        'value': "1",
      }), // Assuming "1" means present
    );

    if (response.statusCode == 200) {
      print('✅ Attendance Marked: $roll, $date');
      return true;
    } else {
      print(
        '❌ Attendance Failed: $roll, $date. Status: ${response.statusCode}',
      );
      return false;
    }
  }*/


  Future<bool> markAttendance({
    required String rollNumber,
    required String subjectCode,
    required String sectionId,
    required String sessionId, // overview.subjectCode
    required String submittedCode,
  }) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {

      // 1. ✅ Update presentStudents in overview
      final sessionRef =  _firestore.collection('courses')
        .doc(studentData!.course)
        .collection('semesters')
        .doc(studentData!.sem)
        .collection('sections')
        .doc(studentData!.section)
        .collection('attendance_sessions')
        .doc(sessionId);

      await sessionRef.update({
        'students': FieldValue.arrayUnion([rollNumber])
      });

      // 2. ✅ Increment student's attendance in their subject
      final studentRef = _firestore
          .collection('students')
          .doc(rollNumber)
          .collection('attendance')
          .doc(subjectCode);

      studentRef.update({
        'total_present': FieldValue.increment(1),
        'subjectCode': subjectCode,
      });

      return true;

    } catch (e) {
      print('Error in markAttendance: $e');
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoadingDashboard) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _primaryBlue)),
      );
    }

    if (_dashboardErrorMessage != null || studentData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sentiment_dissatisfied_outlined,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  _dashboardErrorMessage ??
                      "Failed to load your profile or subjects.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Please ensure your internet connection is stable and try again. If the issue persists, contact support.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _initializeDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text(
                    "Retry Load",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                if (studentData == null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const RegisterStudent(),
                        ), // Assuming this is the correct registration page
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      // Complementary neutral color
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.app_registration, size: 20),
                    label: const Text(
                      "Go to Registration",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            iconSize: 28,
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const StudentProfile()),
              );
            },
            icon: const Icon(Icons.person_rounded, color: _primaryBlue),
          ),
        ),
        title: Text(
          'Welcome, ${studentData!.firstName}!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Consistent padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              TextWidget(
                text: 'Your Subjects',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              const SizedBox(height: 15),
              _studentSubjects.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "No subjects found for your semester. Please contact administration.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _studentSubjects.length,
                  itemBuilder: (context, index) {
                          final subject = _studentSubjects[index];

                          final attendanceOverviewDocRef = FirebaseFirestore.instance
                              .collection('courses')
                              .doc(studentData!.course)
                              .collection('semesters')
                              .doc(studentData!.sem)
                              .collection('sections')
                              .doc(studentData!.section)
                              .collection('attendance_sessions')
                              .doc(subject.subjectCode);

                          return Card(
                            color: Colors.blueGrey.shade50,
                            shadowColor: Colors.blueGrey.withOpacity(0.1),
                            elevation: 8,
                            // Increased elevation for more lift
                            margin: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 0,
                            ),
                            // Increased vertical margin
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                22,
                              ), // More rounded corners
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              // Match card radius
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                // Increased padding
                                leading: CircleAvatar(
                                  backgroundColor: _primaryBlue.withOpacity(
                                    0.1,
                                  ),
                                  child: Text(
                                    subject.subjectName
                                        .split(' ')
                                        .first
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: _primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  subject.subjectName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  'Code: ${subject.subjectCode} | Section: ${studentData!.section}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                // todo : Add teacher name according to the section and subject
                                childrenPadding: const EdgeInsets.all(24),
                                // Increased padding for expanded content
                                children: [
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: attendanceOverviewDocRef
                                        .snapshots(),
                                    builder: (context, snapshot) {

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }

                                      if (!snapshot.data!.exists) {
                                        print(snapshot.data);
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'No data: ${snapshot.data}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Error loading attendance session: ${snapshot.error}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }

                                      final overview = AttendanceOverviewModel.fromFirestore(snapshot.data!,);

                                      final bool isExpired = overview.expTime != null &&
                                          overview.expTime!.toDate().isBefore(DateTime.now());

                                      print(isExpired);

                                      final bool isThisSubjectOpen = overview.isOpen &&
                                          overview.subjectCode == subject.subjectCode &&
                                          !isExpired;


                                      if (!isThisSubjectOpen) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TextWidget(
                                              text: 'No active attendance session',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                            const SizedBox(height: 8),
                                            _buildStudentAttendanceSummary(subject),
                                          ],
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        // Align text to start
                                        children: [
                                          TextWidget(
                                            text: isMarked ? 'Attendance Marked' :'Mark Attendance',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryBlue,
                                          ),
                                          const SizedBox(height: 15),
                                          if(isMarked == false)
                                          TextFormField(
                                            controller: _codeController,
                                            keyboardType: TextInputType.number,
                                            maxLength: 6,
                                            decoration: InputDecoration(
                                              hintText: 'Enter attendance code',
                                              counterText: "",
                                              prefixIcon: const Icon(
                                                Icons.vpn_key_rounded,
                                                color: _primaryBlue,
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey.shade50,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: _primaryBlue,
                                                  width: 2,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.isEmpty) {
                                                return 'Code cannot be empty';
                                              }
                                              if (v.length != 6) {
                                                return 'Code must be 6 digits';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          Center(
                                            child: SizedBox(
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.6,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  backgroundColor: _primaryBlue,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  elevation: 5,
                                                ),
                                                onPressed: (_isMarkingAttendance || isMarked)
                                                    ? null
                                                    : () async {
                                                        final isValid =
                                                            _formKey
                                                                .currentState
                                                                ?.validate() ??
                                                            false;
                                                        if (!isValid) return;

                                                        setState(
                                                          () =>
                                                              _isMarkingAttendance =
                                                                  true,
                                                        );
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).hideCurrentSnackBar();

                                                        try {
                                                          if (overview.attendanceCode.isEmpty) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  '❌ Attendance code not available or session invalid.',
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .orange,
                                                              ),
                                                            );
                                                            return;
                                                          }

                                                          if (_codeController.text.trim() != overview.attendanceCode) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  '❌ Incorrect attendance code.',
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                            return;
                                                          }

                                                          final success = await markAttendance(
                                                            rollNumber: studentData!.rollNumber,
                                                            subjectCode: subject.subjectCode,
                                                            sectionId: studentData!.section,
                                                            sessionId: overview.subjectCode,
                                                            submittedCode: _codeController.text.trim(),
                                                          );

                                                          if (success) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  '✅ Attendance marked successfully!',
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );
                                                            setState(() {
                                                              _markedSubjectCode = subject.subjectCode;
                                                              _codeController.clear();
                                                            });
                                                           isMarked = _markedSubjectCode == subject.subjectCode;

                                                          } else {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  '❌ Failed to mark attendance. Please try again.',
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          print(
                                                            '❌ Error marking attendance: $e',
                                                          );
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '❌ An error occurred: ${e.toString()}',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        } finally {
                                                          setState(
                                                            () =>
                                                                _isMarkingAttendance =
                                                                    false,
                                                          );
                                                        }
                                                      },
                                                icon: _isMarkingAttendance
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : const Icon(
                                                        Icons
                                                            .check_circle_outline_rounded,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                label: Text(
                                                  _isMarkingAttendance
                                                      ? 'Marking...'
                                                      : 'Mark Present',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _buildStudentAttendanceSummary(
                                            subject,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildStudentAttendanceSummary(SubjectModel subject) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(studentData!.rollNumber)
          .collection('attendance')
          .doc(subject.subjectCode) // Assuming subjectCode is unique for doc ID
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Loading attendance summary...',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No attendance records found yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final totalPresent = data['total_present'] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: LabeledText(
            label: 'Attendance: ',
            value: '$totalPresent / (Total Classes Placeholder)',
            // You'll need to fetch total classes held
            labelWeight: FontWeight.w600,
            valueColor: _primaryBlue,
            labelFontSize: 15,
            valueFontSize: 15,
          ),
        );
      },
    );
  }
}
