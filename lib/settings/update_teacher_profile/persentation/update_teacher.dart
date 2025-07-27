import 'package:attendence/core/app_colors.dart';
import 'package:attendence/core/widgets/lable_text.dart';
import 'package:attendence/core/widgets/text_widget.dart';
import 'package:attendence/user/teacher_register/data/teacher_register_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for clipboard

class UpdateTeacher extends StatefulWidget {
  final String subjectName;
  final String subjectCode;
  final String section;
  final String course;
  final String semester;
  final String? sheetUrl;
  final String email;
  final String docId;

  const UpdateTeacher({
    super.key,
    required this.subjectName,
    required this.subjectCode,
    required this.docId,
    required this.email,
    required this.section,
    this.sheetUrl,
    required this.course,
    required this.semester,
  });

  @override
  State<UpdateTeacher> createState() => _UpdateTeacherState();
}

class _UpdateTeacherState extends State<UpdateTeacher> {
  final RegisterTeacherDatasource _teacherService = RegisterTeacherDatasource();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sheetUrl = TextEditingController();
  final TextEditingController _course = TextEditingController();
  final TextEditingController _semester = TextEditingController();
  final TextEditingController _sheetScript = TextEditingController();

  bool _isLoading = false;

  // Properly formatted script text
  final String _scriptText = '''function doPost(e) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  const data = sheet.getDataRange().getValues();
  const json = JSON.parse(e.postData.contents);
  const rollNumber = json.rollNumber;
  const date = json.date;
  const value = json.value;
  
  let dateColIndex = data[0].indexOf(date);
  if (dateColIndex === -1) {
    dateColIndex = data[0].length;
    sheet.getRange(1, dateColIndex + 1).setValue(date);
  }
  
  for (let i = 1; i < data.length; i++) {
    if (data[i][1].toString().trim() === rollNumber.toString().trim()) {
      sheet.getRange(i + 1, dateColIndex + 1).setValue(value);
      return ContentService.createTextOutput('Attendance marked for roll number ' + rollNumber);
    }
  }
  
  return ContentService.createTextOutput('Roll number not found: ' + rollNumber);
}''';

  @override
  void initState() {
    super.initState();
    _sheetUrl.text = widget.sheetUrl ?? '';
    _semester.text = widget.semester;
    _sheetUrl.text = widget.sheetUrl ?? '';
    _course.text = widget.course;
    _sheetScript.text = _scriptText;
  }

  @override
  void dispose() {
    _sheetUrl.dispose();
    _semester.dispose();
    _course.dispose();
    _sheetScript.dispose();
    super.dispose();
  }

  // Function to copy script to clipboard
  void _copyScriptToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _scriptText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              TextWidget(
                text: 'Script copied to clipboard!',
                color: Colors.white,
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: TextWidget(
          text: 'Update Subject',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            iconSize: 24,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primary),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:  AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color:  AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const TextWidget(
                      text: 'Subject Information',
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Subject details card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [ AppColors.primary, AppColors.primaryLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 20,
                                child: TextWidget(
                                  text: widget.subjectName.isNotEmpty
                                      ? widget.subjectName[0].toUpperCase()
                                      : "S",
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: widget.subjectName,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: TextWidget(
                                      text: 'Code: ${widget.subjectCode}',
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: 'Section',
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    const SizedBox(height: 4),
                                    TextWidget(
                                      text: widget.section,
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.grey.shade300,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: 'Course',
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      const SizedBox(height: 4),
                                      TextWidget(
                                        text: widget.course,
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Update form section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const TextWidget(
                      text: 'Update Details',
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Form card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildReadOnlyField('Course', _course),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildReadOnlyField('Semester', _semester),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildScriptFieldWithCopy('Sheet Script', _sheetScript),
                        const SizedBox(height: 24),
                        _buildTextField('Attendance Sheet URL', _sheetUrl),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Update button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _showUpdateConfirmation();
                      }
                    },
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.update_outlined, size: 22),
                    label: TextWidget(
                      text: _isLoading ? 'Updating...' : 'Update Subject',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
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
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        const SizedBox(height: 8),
        TextFormField(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.url,
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            filled: true,
            fillColor:AppColors.background,
            prefixIcon: Icon(
              Icons.link_outlined,
              color:AppColors.primary,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            if (!value.startsWith('http')) {
              return 'Please enter a valid URL';
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
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextWidget(
            text: controller.text,
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // New widget for script field with copy button
  Widget _buildScriptFieldWithCopy(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: label,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            ElevatedButton.icon(
              onPressed: _copyScriptToClipboard,
              icon: const Icon(Icons.copy, size: 16),
              label: const TextWidget(
                text: 'Copy',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              controller.text,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showUpdateConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool _dialogLoading = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.update_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const TextWidget(
                  text: 'Update Sheet URL',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ],
            ),
            content: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LabeledText(
                  label: 'Please make sure te followings: ',
                  value: '\n\n1. The script is added in your Google sheet.'
                      '\n\n2. Sheet is deployed with access selected as \'Anyone\'.'
                      '\n\nOnly then paste the new url here.',
                )
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _dialogLoading
                            ? null
                            : () {
                          Navigator.pop(context);
                        },
                        child: const TextWidget(
                          text: 'Cancel',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _dialogLoading
                            ? null
                            : () async {
                          setStateDialog(() {
                            _dialogLoading = true;
                          });
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            await _teacherService.updateAssignedSubject(
                              email: widget.email,
                              assignedSubjectId: widget.docId,
                              sheetUrl: _sheetUrl.text.trim(),
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const TextWidget(
                                    text:
                                    'Sheet URL updated successfully!',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: TextWidget(
                                    text: 'Error: ${e.toString()}',
                                    color: Colors.white,
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        child: _dialogLoading
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const TextWidget(
                          text: 'Update',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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