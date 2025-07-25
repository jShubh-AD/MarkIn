import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceOverviewModel {
  final String subjectCode;
  final bool isOpen;
  final String attendanceCode;
  final Timestamp? expTime;
  final List<String> presentStudents;

  AttendanceOverviewModel({
    required this.subjectCode,
    required this.isOpen,
    required this.expTime,
    required this.attendanceCode,
    required this.presentStudents,
  });

  factory AttendanceOverviewModel.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    if (rawData == null) {
      throw Exception('Attendance document does not exist or is empty.');
    }

    final data = rawData as Map<String, dynamic>;

    return AttendanceOverviewModel(
      attendanceCode: data['attendance_code'] ?? '',
      subjectCode: data['subject_code'] ?? '',
      isOpen: data['is_open'] ?? false,
      expTime: data['expTime'],
      presentStudents: List<String>.from(data['present_students'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_code': subjectCode,
      'is_open': isOpen,
      'expTime': expTime,
      'attendance_code': attendanceCode,
      'present_students': presentStudents,
    };
  }
}
