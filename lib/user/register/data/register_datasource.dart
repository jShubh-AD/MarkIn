import 'package:attendence/subject/data/subject_model.dart';
import 'package:attendence/user/register/data/student_attendance_model.dart';
import 'package:attendence/user/register/data/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterStudentService {
  final studentInstance = FirebaseFirestore.instance.collection('students');
  final courseInstance = FirebaseFirestore.instance.collection('courses');

  /// REGISTER/UPDATE STUDENT DATA

  Future<bool> registerStudents({
    required String email,
    required String firstName,
    required String lastName,
    required String sem,
    required String roll,
    required String course,
    required String section,
    required List<SubjectModel> subjects,
  }) async {
    final docRef = studentInstance.doc(roll.trim());
    final doc = await docRef.get();

    if (!doc.exists) return false;
    final student = StudentModel(
      sem: sem,
      course: course,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: 'student',
      rollNumber: roll,
      section: section,
    );
    await docRef.set(student.toMap());

    for (var subject in subjects) {
      final attendance = SubjectAttendanceModel(
        subjectTeacher: subject.subjectTeacher,
        subjectName: subject.subjectName,
        subjectCode: subject.subjectCode,
        totalPresent: 0,
        markedDates: [],
      );
      await docRef.collection('attendance').doc().set(attendance.toMap());
    }

    return true;
  }

  /// GET COURSES FROM Firestore

  Future<List<String>> getCourses() async {
    final querySnapshot = await courseInstance.get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  /// GET SEMESTER FROM Firestore

  Future<List<String>> getSemesters({required String courseId}) async {
    final querySnapshot = await courseInstance
        .doc(courseId)
        .collection('semesters')
        .get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  /// Get SECTIONS From Firestore

  Future<List<String>> getSections({
    required String courseId,
    required String semId,
  }) async {
    final querySnapshot = await courseInstance
        .doc(courseId)
        .collection('semesters')
        .doc(semId)
        .collection('sections')
        .get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  /// Get SUBJECTS From Firestore

  Future<List<SubjectModel>> getSubjects({
    required String courseId,
    required String semId,
  }) async {
    final querySnapshot = await courseInstance
        .doc(courseId)
        .collection('semesters')
        .doc(semId)
        .collection('subjects_sem3')
        .get();
    return querySnapshot.docs
        .map((doc) => SubjectModel.fromMap(doc.data()))
        .toList();
  }
}
