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
        elevation: 0,
        title: TextWidget(
          text: 'Setup Profile',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
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
                      child: _buildTextField('First Name', _firstNameCtrl),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField('Last Name', _lastNameCtrl),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildReadOnlyField('Roll Number', _rollNoCtrl),
                SizedBox(height: 20),
                _buildReadOnlyField('Email', _emailCtrl),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('Select Course', _courses, _selectedCourse, (value) async {
                      final sem = await _studentService.getSemesters(courseId: value!);
                      setState(() {
                        _sem = sem;
                        _selectedCourse = value;
                      });
                    })),
                    SizedBox(width: 16),
                    Expanded(child: _buildDropdown('Select Semester', _sem, _selectedSem, (value) async {
                      final sections = await _studentService.getSections(
                        courseId: _selectedCourse!,
                        semId: value!,
                      );
                      final subjects = await _studentService.getSubjects(
                        courseId: _selectedCourse!,
                        semId: value,
                      );
                      setState(() {
                        _sections = sections;
                        _subjects = subjects;
                        _selectedSem = value;
                      });
                    })),
                  ],
                ),
                SizedBox(height: 20),
                _buildDropdown('Select Section', _sections, _selectedSection,
                        (value) => setState(() => _selectedSection = value)),
                SizedBox(height: 20),
                TextWidget(
                  text: 'Semester Subjects',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return Card(
                      elevation: 2,
                      color: Colors.grey.shade50,
                      shadowColor: Colors.grey.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: formRadius,
                      ),
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
                        subjects: _subjects,
                      );

                      if (registered) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Student registered successfully')),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentDashboard(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Roll number already registered')),
                        );
                      }
                    },
                    child: TextWidget(
                      text: 'Register',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(text: label, fontSize: 14, color: Colors.black87),
        SizedBox(height: 4),
        TextFormField(
          style: TextStyle(color: Colors.black87),
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.name,
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(borderRadius: formRadius),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(text: label, fontSize: 14, color: Colors.black87),
        SizedBox(height: 4),
        TextFormField(
          readOnly: true,
          style: TextStyle(color: Colors.black54),
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: formRadius),
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
        TextWidget(text: label, fontSize: 14, color: Colors.black87),
        SizedBox(height: 4),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          isExpanded: true,
          value: selectedValue,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(borderRadius: formRadius),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select' : null,
        ),
      ],
    );
  }
}
