import 'dart:async';
import 'dart:math';
import 'package:attendence/core/app_colors.dart';
import 'package:attendence/core/auth/aurth_service.dart';
import 'package:attendence/teacher_homepage/data/teacher_dashboard_datasource.dart';
import 'package:attendence/user/signin/presentaton/signin_page.dart';
import 'package:attendence/user/teacher_register/data/teacher_register_model.dart';
import 'package:attendence/user/teacher_register/presentation/teacher_register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/text_widget.dart';
import '../../profile/teacher_profile/teacher_proflie_presentation/teacher_profile.dart';
import '../../student_homepage/data/students_data/attendance_overview_model.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final fbStore = FirebaseFirestore.instance.collection('attendance');

  final TeacherDashboardDatasource teacherDashService =
  TeacherDashboardDatasource();

  bool? _isLoadingDashboard = false;
  String? _dashboardErrorMessage;
  static const Color _primaryBlue = Color(0xFF1976D2); // Updated to match theme

  // Theme colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryLightColor = Color(0xFF42A5F5);
  static const Color accentColor = Color(0xFF2196F3);
  static const Color surfaceColor = Colors.white;
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);

  TeacherRegisterModel? _teacherData;
  Map<String, AssignedSubject>? _assignedSubjects;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<String?> _loadTeacherId() async {
    try {
      final pref = await SharedPreferences.getInstance();
      return pref.getString('teacher_id');
    } catch (e) {
      throw Exception('No Teacher ID found');
    }
  }

  Future<void> _initializeDashboard() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardErrorMessage = null;
    });
    try {
      final teacherId = await _loadTeacherId();
      if (teacherId == null || teacherId.isEmpty) {
        throw Exception(
          "Teacher ID not found. Please register.",
        );
      }

      final teacherDoc = await teacherDashService.getTeacherData(teacherId);
      if (teacherDoc == null) {
        throw Exception(
          "Teacher data not found for ID: $teacherId. Please complete registration.", // Changed from Student data
        );
      }

      setState(() {
        _teacherData = teacherDoc;
        _assignedSubjects = teacherDoc.assignedSubjects;
      });
    } catch (e) {
      setState(() {
        _dashboardErrorMessage = "Failed to load dashboard data: ${e.toString()}";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: _dashboardErrorMessage ??
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDashboard!) {
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

    if (_dashboardErrorMessage != null || _teacherData == null) {
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
                    text: _dashboardErrorMessage ??
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
                  if (_teacherData == null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AuthService().logOut(); // Ensure logout on going to sign in
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: surfaceColor,
        elevation: 0,
        title: TextWidget(
          text: 'Hi ${_teacherData!.firstName}',
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
                MaterialPageRoute(builder: (c) =>  TeacherProfile(teacherData: _teacherData!,)),
              );
            },
            icon: const Icon(Icons.person_rounded, color: primaryColor),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dashboard_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const TextWidget(
                  text: 'Manage Attendance',
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: (_assignedSubjects == null || _assignedSubjects!.isEmpty)
                  ? Center(
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
                        text: "No subjects assigned yet.",
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
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _assignedSubjects!.length,
                itemBuilder: (context, index) {
                  final subjectEntry = _assignedSubjects!.entries.elementAt(index);
                  final subjectId = subjectEntry.key; // This is the subject code
                  final assignedSubject = subjectEntry.value; // Has subjectName and section

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
                        splashColor: Colors.transparent,
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
                              text: assignedSubject.subjectName.isNotEmpty
                                  ? assignedSubject.subjectName
                                  .split(' ')
                                  .first
                                  .substring(0, 1)
                                  .toUpperCase()
                                  : '',
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: TextWidget(
                          text: assignedSubject.subjectName,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: TextWidget(
                            text: 'Code: ${assignedSubject.subjectId} \nSem: ${assignedSubject.semesterId} | Sec: ${assignedSubject.sectionId}',
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: fbStore.doc(subjectId.trim()).snapshots(),
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
                                          text: 'Error loading attendance status',
                                          color: errorColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final data = snapshot.data?.data() as Map<String, dynamic>?;
                              final isOpen = data?['isOpen'] ?? false;

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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isOpen
                                                    ? successColor.withOpacity(0.1)
                                                    : errorColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                isOpen ? Icons.lock_open : Icons.lock_outline,
                                                color: isOpen ? successColor : errorColor,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            TextWidget(
                                              text: isOpen
                                                  ? 'Status: Open'
                                                  : 'Status: Closed',
                                              color: isOpen ? successColor : errorColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ],
                                        ),
                                        Switch.adaptive(
                                          value: isOpen,
                                          activeColor: primaryColor,
                                          inactiveThumbColor: Colors.grey.shade400,
                                          inactiveTrackColor: Colors.grey.shade300,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (val) async {
                                            try {
                                              await fbStore.doc(subjectId.trim()).set(
                                                  {'isOpen': val}, SetOptions(merge: true)
                                              );
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: TextWidget(
                                                      text: "Error updating status: ${e.toString()}",
                                                      color: Colors.white,
                                                    ),
                                                    backgroundColor: errorColor,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    CodeCountdownButton(
                                      sheetUrl: assignedSubject.sheetUrl!,
                                      isOpen: isOpen,
                                      subjectId: subjectId,
                                      section: assignedSubject.sectionId.toLowerCase(),
                                    ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 👇 Separate widget to handle countdown and code generation
class CodeCountdownButton extends StatefulWidget {
  final bool isOpen;
  final String subjectId;
  final String section;
  final String sheetUrl;

  const CodeCountdownButton({
    super.key,
    required this.isOpen,
    required this.sheetUrl,
    required this.subjectId,
    required this.section,
  });

  @override
  State<CodeCountdownButton> createState() => _CodeCountdownButtonState();
}

class _CodeCountdownButtonState extends State<CodeCountdownButton> {
  String? _code;
  String _buttonText = "Generate Code";
  bool _isDisabled = false;
  Timer? _timer;



  @override
  void initState() {
    super.initState();
    _checkExistingCode();
  }

  Future<void> _checkExistingCode() async {
    final fbStore = FirebaseFirestore.instance.collection('attendance');
    final docRef = fbStore.doc(widget.subjectId.trim());

    // Listen to changes for real-time updates to code and time
    docRef.snapshots().listen((snapshot) {
      if (!mounted) return; // Prevent setState on disposed widget

      if (snapshot.exists && snapshot.data() != null) {
        final attendance = AttendanceOverviewModel.fromFirestore(snapshot);


        // If attendance is manually closed, reset UI immediately
        if(!attendance.isOpen && _isDisabled){
          setState(() {
            _isDisabled = false;
            _buttonText = 'Generate Code' ;
            _code = null;
          });
          _timer?.cancel();
          return;
        }

        if (attendance.attendanceCode.isNotEmpty && attendance.expTime != null && attendance.isOpen) {
          final expTime = attendance.expTime!.toDate();
          final remainingSeconds = expTime.difference(DateTime.now()).inSeconds;

          if (remainingSeconds > 0) {
            setState(() {
              _code = attendance.attendanceCode;
              _isDisabled = true;
              _buttonText = "Wait (${remainingSeconds}s)";
            });
            _startLocalCountdown(remainingSeconds);
          } else {
            // Code has expired based on Firestore, reset locally
            setState(() {
              _isDisabled = false;
              _buttonText = 'Generate Code';
              _code = null;
            });
            _timer?.cancel(); // Ensure any running timer is cancelled
            // Clean up Firestore if it wasn't already
            docRef.set({
              'isOpen': false,
              'code': FieldValue.delete(),
              'expTime': FieldValue.delete(),
            }).catchError((e) => print("Error cleaning up expired code: $e"));
          }
        } else if (!attendance.isOpen && _code != null) {
          // If attendance was open but is now closed from somewhere else
          setState(() {
            _code = null;
            _isDisabled = false;
            _buttonText = 'Generate Code';
          });
          _timer?.cancel();
        }
      } else {
        // Document or relevant fields don't exist, reset UI
        setState(() {
          _isDisabled = false;
          _buttonText = 'Generate Code';
          _code = null;
        });
        _timer?.cancel();
      }
    });
  }

  void _startLocalCountdown(int initialSeconds) {
    _timer?.cancel(); // Cancel any existing timer
    int seconds = initialSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (seconds == 0) {
        setState(() {
          _isDisabled = false;
          _buttonText = 'Generate Code';
          _code = null;
        });
        timer.cancel();
      } else {
        seconds--;
        setState(() {
          _buttonText = "Wait (${seconds}s)";
        });
      }
    });
  }

  void _startCountdown() async {
    setState(() {
      _isDisabled = true;
      _code = (100000 + Random().nextInt(900000)).toString(); // generate 6-digit code
      _buttonText = "Wait (30s)";
    });

    final fbStore = FirebaseFirestore.instance.collection('attendance');
    final docRef = fbStore.doc(widget.subjectId.trim());

    try {
      await docRef.set({
        'code': _code,
        'sheetUrl': widget.sheetUrl,
        'isOpen': true,
        'expTime': Timestamp.fromDate(DateTime.now().add(const Duration(seconds: 30)))
      }, SetOptions(merge: true));

      _startLocalCountdown(30);

      // This Future.delayed is a fallback to close attendance in Firestore
      // in case the snapshot listener or app closes prematurely.
      Future.delayed(const Duration(seconds: 30), () async {
        // Re-check Firestore state before forcing closure
        final currentDoc = await docRef.get();
        if (currentDoc.exists &&
            currentDoc.data()?['code'] == _code &&
            currentDoc.data()?['isOpen'] == true) {
          await docRef.update({
            'isOpen': false,
            'code': FieldValue.delete(),
            'expTime': FieldValue.delete(),
          }).catchError((e) => print("Error cleaning up expired code in delayed: $e"));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: "Error generating code: ${e.toString()}",
              color: Colors.white,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isDisabled = false;
          _buttonText = 'Generate Code';
          _code = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_code != null && widget.isOpen) // Only show code if attendance is explicitly open
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.key,
                    color: AppColors.success,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextWidget(
                        text: 'Generated Code',
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 2),
                      TextWidget(
                        text: '$_code',
                        color: AppColors.success,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_isDisabled || !widget.isOpen) ? null : _startCountdown,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isOpen && !_isDisabled ? AppColors.primary : Colors.grey.shade400,
              foregroundColor: Colors.white,
              elevation: widget.isOpen && !_isDisabled ? 2 : 0,
              shadowColor: AppColors.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
            child: _isDisabled
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextWidget(
                  text: _buttonText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isOpen ? Icons.generating_tokens : Icons.lock_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                TextWidget(
                  text: _buttonText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}