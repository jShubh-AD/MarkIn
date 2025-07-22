import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectAssignment {
  final String assignmentId; // e.g., "BCA_3_BCA301_A"
  final String courseId;
  final String semesterId;
  final String sectionId;
  final String subjectId;
  final String teacherName;
  final String? teacherId;
  final bool isAssigned;

  SubjectAssignment({
    required this.assignmentId,
    required this. teacherName,
    required this.courseId,
    required this.semesterId,
    required this.sectionId,
    required this.subjectId,
    this.teacherId,
    required this.isAssigned,
  });

  factory SubjectAssignment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectAssignment(
      assignmentId: doc.id,
      teacherName: data['teacherName'],
      courseId: data['courseId'],
      semesterId: data['semesterId'],
      sectionId: data['sectionId'],
      subjectId: data['subjectId'],
      teacherId: data['teacherId'],
      isAssigned: data['isAssigned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherName': teacherName,
      'courseId': courseId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'isAssigned': isAssigned,
    };
  }
}
