import 'package:attendence/Homepage/student_dashboard.dart';
import 'package:attendence/Homepage/teacher_dashboard.dart';
import 'package:attendence/core/widgets/lable_text.dart';
import 'package:attendence/core/widgets/text_widget.dart';
import 'package:attendence/subject/data/subject_model.dart';
import 'package:attendence/subject/subject_assignment/data/subject_assignment_model.dart';
import 'package:attendence/user/student_register/data/student_attendance_model.dart';
import 'package:attendence/user/teacher_register/data/teacher_register_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../student_register/data/register_datasource.dart';

class TeacherRegister extends StatefulWidget {
  const TeacherRegister({super.key});

  @override
  State<TeacherRegister> createState() => _TeacherRegisterState();
}

class _TeacherRegisterState extends State<TeacherRegister> {
  final RegisterStudentService _studentService = RegisterStudentService();
  final RegisterTeacherDatasource _teacherService = RegisterTeacherDatasource();
  final BorderRadius formRadius = BorderRadius.circular(12);

  final _formKey = GlobalKey<FormState>();
  List<String> _sections = [];
  List<String> _courses = [];
  List<String> _sem = [];
  List<SubjectModel> _subjects = [];
  List<SubjectAssignment> _previewAssignedSujects = [];

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _rollNoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _subjectName = TextEditingController();

  String? _selectedSection;
  SubjectModel? _selectedSubjects;
  String? _selectedCourse;
  String? _selectedSubjectCode;
  String? _selectedSem;

  bool _isLoading = true;
  bool? _isSubjectAvailable;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Ensure currentUser is not null before accessing its email
    _emailCtrl.text = FirebaseAuth.instance.currentUser?.email ?? '';
    //_isLoading = false;
    _initializeProfileSetup();
  }

  Future<void> _initializeProfileSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      //await _loadRollFromPrefs();
      await _loadCourses();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load initial data: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage ?? "An unknown error occurred during initialization",
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    try {
      final coursesLoaded = await _teacherService.getCourses();
      setState(() {
        _courses = coursesLoaded;
      });
    } catch (e) {
      throw Exception("Failed to load courses: ${e.toString()}");
    }
  }

  /*Future<void> _loadRollFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRoll = prefs.getString('roll_number');
      if (savedRoll != null && savedRoll.isNotEmpty) {
        _rollNoCtrl.text = savedRoll;
      } else {
        throw Exception("Roll number not found in preferences.");
      }
    } catch (e) {
      throw Exception("Failed to load roll number from preferences: ${e.toString()}");
    }
  }*/

  Future<void> checkAssignmentStatus({
    required String courseId,
    required String semesterId,
    required String subjectId,
    required String sectionId,
  }) async {
    try {
      final bool isAvailable = await _teacherService
          .checkAssignmentAvailability(
            courseId: courseId,
            semesterId: semesterId,
            subjectId: subjectId,
            sectionId: sectionId,
          );

      setState(() {
        _isSubjectAvailable = isAvailable;
      });

      if (!isAvailable) {
        // If it's NOT available (meaning it's assigned)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              color: Colors.white,
              text: 'Subject $_selectedSubjectCode is already assigned to another teacher for Section: $_selectedSection.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      setState(() {
        _isSubjectAvailable = false;
        _errorMessage = "Error checking assignment status: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking availability: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _rollNoCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextWidget(
          text: 'Setup Profile',
          fontSize: 24,
          fontWeight: FontWeight.w700, // Slightly bolder title
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ), // Ensure back button is visible
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
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _initializeProfileSetup,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(
                  20,
                ), // Increased padding for more space
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'First Name',
                              _firstNameCtrl,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Last Name', _lastNameCtrl),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 24), // Increased spacing
                      //   _buildReadOnlyField('Roll Number', _rollNoCtrl),
                      const SizedBox(height: 24),
                      _buildReadOnlyField('Email', _emailCtrl),
                      const SizedBox(height: 24),

                      /// -------------------------- Card for Adding Subject and checking if its available or not ------------------------------------------------
                      Card(
                        elevation: 8,
                        color: Colors.blueGrey.shade100,
                        shadowColor: Colors.blueGrey.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              TextWidget(
                                text: 'Add Subjects',
                                fontSize: 18, // Slightly larger font size
                                fontWeight: FontWeight.w700, // Bolder
                                color: Colors.black87,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown(
                                      'Select Course',
                                      _courses,
                                      _selectedCourse,
                                      (value) async {
                                        if (value == null) return;
                                        try {
                                          final sem = await _studentService
                                              .getSemesters(courseId: value);
                                          setState(() {
                                            _sem = sem;
                                            _selectedCourse = value;
                                            _selectedSem = null;
                                            _selectedSection = null;
                                            _selectedSubjectCode = null;
                                            _isSubjectAvailable = null;
                                            _sections = [];
                                            _subjects = [];
                                          });
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Failed to load semesters: ${e.toString()}",
                                              ),
                                            ),
                                          );
                                          // Keep selected course, but clear dependent fields
                                          setState(() {
                                            _selectedSem = null;
                                            _selectedSection = null;
                                            _selectedSubjectCode = null;
                                            _isSubjectAvailable = null;
                                            _sections = [];
                                            _subjects = [];
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildDropdown(
                                      'Select Semester',
                                      _sem,
                                      _selectedSem,
                                      (value) async {
                                        if (value == null ||
                                            _selectedCourse == null) {
                                          return;
                                        }
                                        try {
                                          final sections = await _studentService
                                              .getSections(
                                                courseId: _selectedCourse!,
                                                semId: value,
                                              );
                                          final subjects = await _studentService
                                              .getSubjects(
                                                courseId: _selectedCourse!,
                                                semId: value,
                                              );
                                          setState(() {
                                            _selectedSubjectCode = null;
                                            _isSubjectAvailable = null;
                                            _sections = sections;
                                            _subjects = subjects;
                                            _selectedSem = value;
                                            _selectedSection = null;
                                          });
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Failed to load sections/subjects: ${e.toString()}",
                                              ),
                                            ),
                                          );
                                          // Keep selected semester, but clear dependent fields
                                          setState(() {
                                            _sections = [];
                                            _subjects = [];
                                            _selectedSubjectCode = null;
                                            _isSubjectAvailable = null;
                                            _selectedSection = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildDropdown(
                                'Select Subject Code',
                                _subjects.map((sub) => sub.subjectCode).toList(),
                                _selectedSubjectCode,
                                (value) => setState(() {
                                  _selectedSubjects = _subjects.firstWhere(
                                        (sub) {
                                          return sub.subjectCode == value;
                                        }
                                  );
                                  _selectedSubjectCode = value;
                                  _isSubjectAvailable = null;
                                  _subjectName.text = _selectedSubjects!.subjectName;
                                }),
                              ),
                              const SizedBox(height: 24),
                                _buildReadOnlyField('Subject name', _subjectName),

///   ----------------------------- Section selection -----------------------------
                              const SizedBox(height: 24),
                              _buildDropdown(
                                'Select Section',
                                _sections,
                                _selectedSection,
                                (value) {
                                  setState(() {
                                    _selectedSection = value;
                                  });
                                  if (_selectedCourse != null &&
                                      _selectedSem != null &&
                                      _selectedSubjectCode != null &&
                                      _selectedSection != null) {
                                    checkAssignmentStatus(
                                      courseId: _selectedCourse!,
                                      semesterId: _selectedSem!,
                                      subjectId: _selectedSubjectCode!,
                                      sectionId: value!,
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 24),

                              /// -------------------------- SUBJECT AVAILABLE OR NOT  TEXT ---------------------------
                              if (_isSubjectAvailable == false &&
                                  _isSubjectAvailable != null)
                                TextWidget(
                                  text:
                                      'Subject not available for the selected section.',
                                  color: Colors.red, // Error color
                                  fontSize: 16,
                                ),
                              const SizedBox(height: 12),

                              /// -------------------------- Assign Me BUTTON ---------------------------
                              // Check for _isSubjectAvailable != null to ensure a check has happened
                              if (_isSubjectAvailable != null &&
                                  _selectedSection != null &&
                                  _selectedSubjectCode != null)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isSubjectAvailable!
                                          ? const Color(0xFF1E88E5)
                                          : Colors.grey,
                                      // Material Blue 600
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      // Taller button
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ), // Using formRadius value for consistency
                                      ),
                                      elevation: 8, // More prominent shadow
                                    ),
                                    onPressed: (_isSubjectAvailable ?? false)
                                        ? () async {
                                      if(_formKey.currentState?.validate() ?? false) {

                                        try {
                                          final assignmentId = '${_selectedCourse}_${_selectedSem}_${_selectedSubjectCode}_$_selectedSection';
                                          final assignedSubject = SubjectAssignment(
                                            subjectName: _subjectName.text,
                                            courseId: _selectedCourse!,
                                            semesterId: _selectedSem!,
                                            subjectId: _selectedSubjectCode!,
                                            sectionId: _selectedSection!,
                                            teacherId: _emailCtrl.text,
                                            teacherName: '${_firstNameCtrl.text} ${_lastNameCtrl.text}',
                                            assignmentId: assignmentId,
                                            isAssigned: true,
                                            );

                                          _teacherService.assignSubjectToTeacher(assignedSubject: assignedSubject);
                                          setState(() {
                                            _previewAssignedSujects.add(assignedSubject);
                                          });

                                          ScaffoldMessenger
                                              .of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: TextWidget(
                                                color: Colors.white,
                                                  text: 'You are assigned for the Subject: $_selectedSubjectCode for Section: $_selectedSection.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }catch(e){
                                          ScaffoldMessenger
                                              .of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: TextWidget(
                                                color: Colors.white,
                                                  text: 'Could not assign the Subject: $_selectedSubjectCode for $_selectedSection to you.\nContact support team.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                    : null,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : TextWidget(
                                            text: 'Assign Me',
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight:
                                                FontWeight.w700, // Bolder text
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      /// --------------------------------------- Added subjects by the teacher ---------------------------------------
                      const SizedBox(height: 30),
                      TextWidget(
                        text: 'Assigned Subjects',
                        fontSize: 18, // Slightly larger font size
                        fontWeight: FontWeight.w700, // Bolder
                        color: Colors.black87,
                      ),
                      const SizedBox(height: 12),
                      // Spacing below title
                      _previewAssignedSujects.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0,
                                ),
                                child: Text(
                                  _selectedSection == null
                                      ? "Please select a subject and section to view subjects."
                                      : "No subjects found for the selected section.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _previewAssignedSujects.length,
                              itemBuilder: (context, index) {
                                final _assignedSubjects = _previewAssignedSujects[index];
                                return Card(
                                  elevation: 4,
                                  color: Colors.blueGrey.shade50.withOpacity(0.5),
                                  shadowColor: const Color(0xFF1E88E5).withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4), // spacing for icon
                                            LabeledText(
                                              label: 'Subject: ',
                                              value: _assignedSubjects.subjectName,
                                              labelWeight: FontWeight.w700,
                                              valueColor: Colors.black87,
                                              labelFontSize: 16,
                                              valueFontSize: 16,
                                            ),
                                            const SizedBox(height: 4),
                                            LabeledText(
                                              label: 'Subject Code: ',
                                              value: _assignedSubjects.subjectId,
                                              labelWeight: FontWeight.w600,
                                              valueColor: Colors.black87,
                                              labelFontSize: 16,
                                              valueFontSize: 16,
                                            ),
                                            const SizedBox(height: 4),
                                            LabeledText(
                                              label: 'Teacher:  ',
                                              value: _assignedSubjects.teacherName,
                                              labelWeight: FontWeight.w600,
                                              labelFontSize: 16,
                                              valueFontSize: 16,
                                              valueColor: Colors.black87,
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: [
                                                Expanded(
                                                  child: LabeledText(
                                                    label: 'Course:  ',
                                                    value: _assignedSubjects.courseId,
                                                    labelWeight: FontWeight.w600,
                                                    labelFontSize: 14,
                                                    valueFontSize: 14,
                                                    valueColor: Colors.grey[700],
                                                  ),
                                                ),
                                                const Text(' | ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                Expanded(
                                                  child: LabeledText(
                                                    label: 'Sem:  ',
                                                    value: _assignedSubjects.semesterId,
                                                    labelWeight: FontWeight.w600,
                                                    labelFontSize: 14,
                                                    valueFontSize: 14,
                                                    valueColor: Colors.grey[700],
                                                  ),
                                                ),
                                                const Text(' | ', style: TextStyle(fontWeight: FontWeight.bold)),
                                                Expanded(
                                                  child: LabeledText(
                                                    label: 'Sec:  ',
                                                    value: _assignedSubjects.sectionId,
                                                    labelWeight: FontWeight.w600,
                                                    labelFontSize: 14,
                                                    valueFontSize: 14,
                                                    valueColor: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ❌ Close Icon
                                      Positioned(
                                        top: -10,
                                        right: -10,
                                        child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _teacherService.removeAssignedSubject(docId: _assignedSubjects.assignmentId);
                                              _previewAssignedSujects.removeAt(index);
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.cancel,
                                            size: 30, // larger icon size
                                            color: Colors.black87,
                                          ),
                                          iconSize: 30, // applies to the whole IconButton
                                          splashRadius: 24, // optional: control splash size
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                              },
                            ),
                      const SizedBox(height: 30),
                      // Increased spacing before button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            // Material Blue 600
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            // Taller button
                            shape: RoundedRectangleBorder(
                              borderRadius: formRadius,
                            ),
                            elevation: 8, // More prominent shadow
                          ),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              if (_selectedCourse == null || _selectedSem == null || _selectedSection == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: TextWidget(text: 'Please select Course, Semester, and Section.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              setState(() {_isLoading = true; });

                              try {
                                final registered = await _teacherService
                                    .registerTeacher(
                                      email: _emailCtrl.text,
                                      firstName: _firstNameCtrl.text,
                                      lastName: _lastNameCtrl.text,
                                      assignedSubjects: _previewAssignedSujects
                                    );

                                if (registered) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: TextWidget(
                                        text: 'You are now registered as a teacher successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TeacherDashboard(),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: TextWidget(text:
                                        'Registration failed: Teacher Id may already be registered or an internal error occurred.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: TextWidget(
                                      text: 'An error occurred during registration: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                          child:
                              _isLoading // Show a CircularProgressIndicator on the button
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : TextWidget(
                                  text: 'Register',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700, // Bolder text
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: label,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ), // Slightly larger label font
        const SizedBox(height: 6), // More space below label
        TextFormField(
          style: const TextStyle(color: Colors.black87),
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.name,
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: Colors.grey.shade50,
            // Light fill color
            border: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: BorderSide.none, // No border for a cleaner look
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: const BorderSide(
                color: Color(0xFF1E88E5),
                width: 2,
              ), // Blue border when focused
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: label,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        const SizedBox(height: 6),
        TextFormField(
          readOnly: true,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            // Slightly darker grey for read-only
            border: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: BorderSide.none, // No focus border for read-only
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          text: label,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          isExpanded: true,
          value: selectedValue,
          decoration: InputDecoration(
            hintText: label.toLowerCase().replaceFirst('select ', ''),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: formRadius,
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.black87)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (v) => v == null
              ? 'Select a ${label.toLowerCase().replaceFirst('select ', '')}'
              : null,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.black54,
          ), // Custom dropdown icon
        ),
      ],
    );
  }
}
