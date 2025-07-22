class SubjectAttendanceModel {
  final String subjectName;
  final String subjectCode;
  final String subjectTeacher;
  final int totalPresent;
  final List<String> markedDates;

  SubjectAttendanceModel({
    required this.subjectName,
    required this.subjectCode,
    required this.subjectTeacher,
    this.totalPresent = 0,
    this.markedDates = const [],
  });

  // Convert model to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'subject_teacher':subjectTeacher,
      'total_present': totalPresent,
      'marked_dates': markedDates,
    };
  }

  // Create model from Firestore map
  factory SubjectAttendanceModel.fromMap(Map<String, dynamic> map) {
    return SubjectAttendanceModel(
      subjectTeacher: map['subject_teacher'] ?? '',
      subjectName: map['subject_name'] ?? '',
      subjectCode: map['subject_code'] ?? '',
      totalPresent: map['total_present'] ?? 0,
      markedDates: List<String>.from(map['marked_dates'] ?? []),
    );
  }
}
