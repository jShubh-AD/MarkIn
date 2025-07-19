import 'package:attendence/Homepage/student_dashboard.dart';
import 'package:attendence/core/widgets/lable_text.dart';
import 'package:attendence/core/widgets/text_widget.dart';
import 'package:attendence/subject/data/subject_model.dart';
import 'package:attendence/user/register/data/register_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterStudent extends StatefulWidget {
  const RegisterStudent({super.key});

  @override
  State<RegisterStudent> createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  final RegisterStudentService _studentService = RegisterStudentService();
  final BorderRadius formRadius = BorderRadius.circular(8);

  final _formKey = GlobalKey<FormState>();
  List<String> _sections = [];
  List<String> _courses = [];
  List<String> _sem = [];
  List<SubjectModel> _subjects = [];

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _rollNoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  String? _selectedSection;
  String? _selectedCourse;
  String? _selectedSem;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = FirebaseAuth.instance.currentUser!.email!;
    _loadRollFromPrefs();
    loadCourses();
  }

  Future<void> loadCourses() async {
    final coursesLoaded = await _studentService.getCourses();
    setState(() {
      _courses = coursesLoaded;
    });
  }

  Future<void> _loadRollFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRoll = prefs.getString('roll_number') ?? '';
    _rollNoCtrl.text = savedRoll;
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
        title: TextWidget(
          text: 'Setup Profile',
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextWidget(text: 'First Name', fontSize: 14),
                          SizedBox(height: 4),
                          TextFormField(
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            controller: _firstNameCtrl,
                            decoration: InputDecoration(
                              hintText: 'First Name',
                              border: OutlineInputBorder(
                                borderRadius: formRadius,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextWidget(text: 'Last Name', fontSize: 14),
                          SizedBox(height: 4),
                          TextFormField(
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            keyboardType: TextInputType.name,
                            controller: _lastNameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Last Name',
                              border: OutlineInputBorder(
                                borderRadius: formRadius,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextWidget(text: 'Roll Number', fontSize: 14),
                SizedBox(height: 4),
                TextFormField(
                  style: TextStyle(color: Colors.grey),
                  readOnly: true,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  controller: _rollNoCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter Roll No.',
                    border: OutlineInputBorder(borderRadius: formRadius),
                    focusedBorder: OutlineInputBorder(borderRadius: formRadius),
                  ),
                ),
                SizedBox(height: 20),
                TextWidget(text: 'Email', fontSize: 14),
                SizedBox(height: 4),
                TextFormField(
                  style: TextStyle(color: Colors.grey),
                  readOnly: true,
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter Email',
                    border: OutlineInputBorder(borderRadius: formRadius),
                    focusedBorder: OutlineInputBorder(borderRadius: formRadius),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(text: 'Select Course', fontSize: 14),
                          SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Select course',
                              border: OutlineInputBorder(
                                borderRadius: formRadius,
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
                            onChanged: (value) async {
                              final sem = await _studentService.getSemesters(
                                courseId: value!,
                              );
                              setState(() {
                                _sem = sem;
                                _selectedCourse = value;
                              });
                            },
                            validator: (v) =>
                                v == null ? 'Please select a course' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(text: 'Select Semester', fontSize: 14),
                          SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Semester',
                              border: OutlineInputBorder(
                                borderRadius: formRadius,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            value: _selectedSem,
                            items: _sem
                                .map(
                                  (s) => DropdownMenuItem<String>(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              final sections = await _studentService
                                  .getSections(
                                    courseId: _selectedCourse!,
                                    semId: value!,
                                  );
                              final subjects = await _studentService
                                  .getSubjects(
                                    courseId: _selectedCourse!,
                                    semId: value,
                                  );
                              setState(() {
                                _subjects = subjects;
                                _sections = sections;
                                _selectedSem = value;
                              });
                            },
                            validator: (v) =>
                                v == null ? 'Please select a section' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextWidget(text: 'Select Section', fontSize: 14),
                SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Section',
                    border: OutlineInputBorder(borderRadius: formRadius),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  value: _selectedSection,
                  items: _sections
                      .map(
                        (s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedSection = value),
                  validator: (v) =>
                      v == null ? 'Please select a section' : null,
                ),
                SizedBox(height: 20),
                TextWidget(text: 'Semester Subjects'),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      shadowColor: Colors.grey.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabeledText(
                              label: 'Subject: ',
                              value: subject.subjectName,
                              labelWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 2),
                            LabeledText(
                              label: 'Teacher: ',
                              value: subject.subjectTeacher,
                              labelWeight: FontWeight.w600,
                              labelFontSize: 15,
                              valueFontSize: 14,
                            ),
                            const SizedBox(height: 2),
                            LabeledText(
                              label: 'Code: ',
                              value: subject.subjectCode,
                              labelWeight: FontWeight.w600,
                              labelFontSize: 15,
                              valueFontSize: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                      sem: _selectedSem.toString(),
                      email: _emailCtrl.text,
                      firstName: _firstNameCtrl.text,
                      lastName: _lastNameCtrl.text,
                      roll: _rollNoCtrl.text,
                      course: _selectedCourse.toString(),
                      section: _selectedSection.toString(),
                      subjects: _subjects
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
                  child: TextWidget(
                    text: 'Register',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
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
