import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/text_widget.dart';
import '../../profile/student_profile/data/student_profile_datasource.dart';
import '../../profile/student_profile/presentation/student_profile.dart';
import '../../subject/data/subject_model.dart';
import '../../user/signin/presentaton/signin_page.dart';
import '../../user/student_register/data/student_model.dart';
import '../data/students_data/attendance_overview_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  StudentModel? studentData;
  List<SubjectModel> _studentSubjects = [];
  bool _isLoadingDashboard = true;
  String? _dashboardErrorMessage;

  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isMarkingAttendance = false;
  String? _markedSubjectCode;

  // Theme colors - matching teacher dashboard
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFF42A5F5);
  static const Color accentColor = Color(0xFF2196F3);
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);

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
      final prefs = await SharedPreferences.getInstance();
      final roll = prefs.getString('roll_number');
      if (roll == null || roll.isEmpty) {
        throw Exception("Roll number not found. Please register.");
      }
      final studentDoc = await StudentProfileDatasource().getStudentData(roll);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text:
                  _dashboardErrorMessage ??
                  "An unknown error occurred loading data, contact support.",
              color: Colors.white,
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _initializeDashboard,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDashboard = false;
        });
      }
    }
  }

  Future<bool> markAttendance({
    required String rollNumber,
    required String subjectCode,
    required String sectionId,
    required String sessionId,
    required String submittedCode,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      final sessionRef = firestore
          .collection('courses')
          .doc(studentData!.course)
          .collection('semesters')
          .doc(studentData!.sem)
          .collection('sections')
          .doc(studentData!.section)
          .collection('attendance_sessions')
          .doc(sessionId);
      await sessionRef.update({
        'students': FieldValue.arrayUnion([rollNumber]),
      });
      final studentRef = firestore
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
      return false;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoadingDashboard) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    const TextWidget(
                      text: "Loading Dashboard...",
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_dashboardErrorMessage != null || studentData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
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
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.sentiment_dissatisfied_outlined,
                      color: errorColor,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextWidget(
                    text:
                        _dashboardErrorMessage ??
                        "Failed to load your profile or subjects.",
                    textAlign: TextAlign.center,
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 12),
                  TextWidget(
                    text:
                        "Please ensure your internet connection is stable and try again. If the issue persists, contact support.",
                    textAlign: TextAlign.center,
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _initializeDashboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: primaryColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const TextWidget(
                        text: "Retry Load",
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (studentData == null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const SignInPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: backgroundColor,
                          foregroundColor: Colors.black87,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        icon: const Icon(Icons.login, size: 20),
                        label: const TextWidget(
                          text: "Go to SignIn",
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Main dashboard content
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: TextWidget(
          text: 'Hi ${studentData!.firstName}',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            iconSize: 24,
            style: IconButton.styleFrom(
              backgroundColor: primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => StudentProfile(
                    studentData: studentData!,
                    subjects: _studentSubjects,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person_rounded, color: primaryColor),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile summary card
            _buildProfileCard(studentData!),
            const SizedBox(height: 28),
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const TextWidget(
                  text: 'Mark Attendance',
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Subjects list
            Expanded(child: _buildSubjectsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(StudentModel student) {
    return Container(
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
        padding: const EdgeInsets.all(24),
        child: Row(
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
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 32,
                child: Icon(Icons.person, size: 32, color: primaryColor),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: '${student.firstName} ${student.lastName}',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextWidget(
                      text: '${student.course} • Sec ${student.section}',
                      fontSize: 13,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextWidget(
                    text: 'Roll: ${student.rollNumber}',
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  const SizedBox(height: 2),
                  TextWidget(
                    text: student.email,
                    fontSize: 13,
                    color: Colors.black54,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    if (_studentSubjects.isEmpty) {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 20),
              TextWidget(
                text: "No subjects found for your semester.",
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: "Please contact administration.",
                color: Colors.grey.shade500,
                fontSize: 14,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              expansionTileTheme: const ExpansionTileThemeData(
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
              ),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              leading: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryLightColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: TextWidget(
                    text: subject.subjectName.isNotEmpty
                        ? subject.subjectName[0].toUpperCase()
                        : "?",
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
              title: TextWidget(
                text: subject.subjectName,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextWidget(
                  text:
                      'Code: ${subject.subjectCode} \nSection: ${studentData!.section}',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: attendanceOverviewDocRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextWidget(
                                text:
                                    'Error loading attendance session: ${snapshot.error}',
                                color: errorColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextWidget(
                                    text:
                                        'No active attendance session for this subject.',
                                    color: Colors.orange.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildStudentAttendanceSummary(subject),
                          ],
                        ),
                      );
                    }

                    final overview = AttendanceOverviewModel.fromFirestore(
                      snapshot.data!,
                    );
                    final bool isExpired =
                        overview.expTime != null &&
                        overview.expTime!.toDate().isBefore(DateTime.now());
                    final bool isSessionActive =
                        overview.isOpen &&
                        overview.subjectCode == subject.subjectCode &&
                        !isExpired;
                    final bool isMarked =
                        _markedSubjectCode == subject.subjectCode;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Session status
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSessionActive
                                      ? successColor.withOpacity(0.1)
                                      : errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  isSessionActive
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSessionActive
                                      ? successColor
                                      : errorColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextWidget(
                                text: isSessionActive
                                    ? 'Session Active'
                                    : 'No Active Session',
                                color: isSessionActive
                                    ? successColor
                                    : errorColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Attendance marking section
                          if (isSessionActive && !isMarked) ...[
                            TextWidget(
                              text: 'Mark Attendance',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _codeController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    decoration: InputDecoration(
                                      hintText: 'Enter attendance code',
                                      counterText: "",
                                      prefixIcon: const Icon(
                                        Icons.vpn_key_rounded,
                                        color: primaryColor,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: errorColor,
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
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: primaryColor.withOpacity(
                                          0.3,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        disabledBackgroundColor:
                                            Colors.grey.shade300,
                                        disabledForegroundColor:
                                            Colors.grey.shade600,
                                      ),
                                      onPressed: _isMarkingAttendance
                                          ? null
                                          : () async {
                                              final isValid =
                                                  _formKey.currentState
                                                      ?.validate() ??
                                                  false;
                                              if (!isValid) return;

                                              setState(
                                                () =>
                                                    _isMarkingAttendance = true,
                                              );

                                              try {
                                                if (overview
                                                    .attendanceCode
                                                    .isEmpty) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Attendance code not available or session invalid.',
                                                      ),
                                                      backgroundColor:
                                                          Colors.orange,
                                                      behavior: SnackBarBehavior
                                                          .floating,
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
                                                        'Incorrect attendance code.',
                                                      ),
                                                      backgroundColor:
                                                          errorColor,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final success =
                                                    await markAttendance(
                                                      rollNumber: studentData!
                                                          .rollNumber,
                                                      subjectCode:
                                                          subject.subjectCode,
                                                      sectionId:
                                                          studentData!.section,
                                                      sessionId:
                                                          overview.subjectCode,
                                                      submittedCode:
                                                          _codeController.text
                                                              .trim(),
                                                    );

                                                if (success) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Attendance marked successfully!',
                                                      ),
                                                      backgroundColor:
                                                          successColor,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                  setState(() {
                                                    _markedSubjectCode =
                                                        subject.subjectCode;
                                                    _codeController.clear();
                                                  });
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Failed to mark attendance. Please try again.',
                                                      ),
                                                      backgroundColor:
                                                          errorColor,
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'An error occurred: ${e.toString()}',
                                                    ),
                                                    backgroundColor: errorColor,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              } finally {
                                                setState(
                                                  () => _isMarkingAttendance =
                                                      false,
                                                );
                                              }
                                            },
                                      icon: _isMarkingAttendance
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .check_circle_outline_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                      label: TextWidget(
                                        text: _isMarkingAttendance
                                            ? 'Marking...'
                                            : 'Mark Present',
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (isMarked) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: successColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: successColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: successColor,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const TextWidget(
                                          text: 'Attendance Marked!',
                                          color: successColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        const SizedBox(height: 2),
                                        TextWidget(
                                          text:
                                              'Your attendance has been recorded successfully.',
                                          color: successColor,
                                          fontSize: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                          _buildStudentAttendanceSummary(subject),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentAttendanceSummary(SubjectModel subject) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(studentData!.rollNumber)
          .collection('attendance')
          .doc(subject.subjectCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const TextWidget(
                  text: 'Loading attendance summary...',
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: errorColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: errorColor, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: TextWidget(
                    text: 'Error loading attendance summary',
                    color: errorColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextWidget(
                        text: 'Attendance Summary',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      const SizedBox(height: 2),
                      TextWidget(
                        text: 'No attendance records found yet.',
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final totalPresent = data['total_present'] ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: 'Attendance Summary',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TextWidget(
                          text: 'Present: ',
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        TextWidget(
                          text: '$totalPresent classes',
                          fontSize: 13,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
