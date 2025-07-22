import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String course;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String sem;
  final String rollNumber;
  final String section;
  final Timestamp? updatedTime;

  StudentModel({
    required this.sem,
    required this.course,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.rollNumber,
    required this.section,
    this.updatedTime,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      sem: data['sem']??'',
      course: data['course'] ?? '',
      email: data['email'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      role: data['role'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      section: data['section'] ?? '',
      updatedTime: data['updated_time'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'course': course,
      'email': email,
      'sem': sem,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'rollNumber': rollNumber,
      'section': section,
      'updated_time': updatedTime,
    };
  }
}
