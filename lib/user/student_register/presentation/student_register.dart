import 'package:attendence/core/widgets/lable_text.dart';
import 'package:attendence/core/widgets/text_widget.dart';
import 'package:attendence/subject/data/subject_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../student_homepage/presentation/student_dashboard.dart';
import '../data/register_datasource.dart';

class RegisterStudent extends StatefulWidget {
  const RegisterStudent({super.key});

  @override
  State<RegisterStudent> createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  final RegisterStudentService _studentService = RegisterStudentService();
  final BorderRadius formRadius = BorderRadius.circular(12);

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

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Ensure currentUser is not null before accessing its email
    _emailCtrl.text = FirebaseAuth.instance.currentUser?.email ?? '';
    _initializeProfileSetup();
  }

  Future<void> _initializeProfileSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _loadRollFromPrefs();
      await _loadCourses();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load initial data: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? "An unknown error occurred during initialization")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourses() async {
    try {
      final coursesLoaded = await _studentService.getCourses();
      setState(() {
        _courses = coursesLoaded;
      });
    } catch (e) {
      throw Exception("Failed to load courses: ${e.toString()}");
    }
  }

  Future<void> _loadRollFromPrefs() async {
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
      backgroundColor: Colors.grey.shade100,
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
        iconTheme: const IconThemeData(color: Colors.black87), // Ensure back button is visible
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
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
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
          padding: const EdgeInsets.all(20), // Increased padding for more space
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField('Last Name', _lastNameCtrl),
                    ),
                  ],
                ),
                const SizedBox(height: 24), // Increased spacing
                _buildReadOnlyField('Roll Number', _rollNoCtrl),
                const SizedBox(height: 24),
                _buildReadOnlyField('Email', _emailCtrl),
                const SizedBox(height: 24),
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
                            final sem = await _studentService.getSemesters(
                              courseId: value,
                            );
                            setState(() {
                              _sem = sem;
                              _selectedCourse = value;
                              _selectedSem = null;
                              _selectedSection = null;
                              _sections = [];
                              _subjects = [];
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to load semesters: ${e.toString()}")),
                            );
                            // Keep selected course, but clear dependent fields
                            setState(() {
                              _selectedSem = null;
                              _selectedSection = null;
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
                          if (value == null || _selectedCourse == null) return;
                          try {
                            final sections = await _studentService.getSections(
                              courseId: _selectedCourse!,
                              semId: value,
                            );
                            final subjects = await _studentService.getSubjects(
                              courseId: _selectedCourse!,
                              semId: value,
                            );
                            setState(() {
                              _sections = sections;
                              _subjects = subjects;
                              _selectedSem = value;
                              _selectedSection = null; // Reset section when semester changes
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to load sections/subjects: ${e.toString()}")),
                            );
                            // Keep selected semester, but clear dependent fields
                            setState(() {
                              _sections = [];
                              _subjects = [];
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
                  'Select Section',
                  _sections,
                  _selectedSection,
                      (value) => setState(() => _selectedSection = value),
                ),
                const SizedBox(height: 30), // Increased spacing
                TextWidget(
                  text: 'Semester Subjects',
                  fontSize: 18, // Slightly larger font size
                  fontWeight: FontWeight.w700, // Bolder
                  color: Colors.black87,
                ),
                const SizedBox(height: 12), // Spacing below title
                _subjects.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      _selectedSem == null
                          ? "Please select a course and semester to view subjects."
                          : "No subjects found for the selected semester.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
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
                      elevation: 4, // More prominent elevation
                      color: Colors.blueGrey.shade50, // Softer background color
                      shadowColor: Colors.blueGrey.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18), // Larger radius
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, // Increased horizontal padding
                          vertical: 15, // Increased vertical padding
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabeledText(
                              label: 'Subject: ',
                              value: subject.subjectName,
                              labelWeight: FontWeight.w700, // Bolder label
                              valueColor: Colors.black87,
                              labelFontSize: 16,
                              valueFontSize: 16,
                            ),
                            const SizedBox(height: 4),

                           // TODO : add Assigned Teacher name for the selected subject according to section.

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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5), // Material Blue 600
                      padding: const EdgeInsets.symmetric(vertical: 16), // Taller button
                      shape: RoundedRectangleBorder(borderRadius: formRadius),
                      elevation: 8, // More prominent shadow
                    ),
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        if (_selectedCourse == null || _selectedSem == null || _selectedSection == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select Course, Semester, and Section.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isLoading = true; // Show loading indicator during registration
                        });

                        try {
                          final registered = await _studentService.registerStudents(
                            sem: _selectedSem!,
                            email: _emailCtrl.text,
                            firstName: _firstNameCtrl.text,
                            lastName: _lastNameCtrl.text,
                            roll: _rollNoCtrl.text,
                            course: _selectedCourse!,
                            section: _selectedSection!,
                            subjects: _subjects,
                          );

                          if (registered) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You are now registered as a student successfully!'),
                                backgroundColor: Colors.green,
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
                              const SnackBar(
                                content: Text('Registration failed: Roll number may already be registered or an internal error occurred.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('An error occurred during registration: ${e.toString()}'),
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
                    child: _isLoading // Show a CircularProgressIndicator on the button
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                        : TextWidget(
                      text: 'Register',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700, // Bolder text
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Bottom padding
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
        TextWidget(text: label, fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87), // Slightly larger label font
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
            fillColor: Colors.grey.shade50, // Light fill color
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
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2), // Blue border when focused
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        TextWidget(text: label, fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        const SizedBox(height: 6),
        TextFormField(
          readOnly: true,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100, // Slightly darker grey for read-only
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        TextWidget(text: label, fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
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
              child: Text(
                item,
                style: const TextStyle(color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Select a ${label.toLowerCase().replaceFirst('select ', '')}' : null,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54), // Custom dropdown icon
        ),
      ],
    );
  }
}