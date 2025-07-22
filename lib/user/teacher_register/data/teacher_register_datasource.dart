import 'package:attendence/user/teacher_register/data/teacher_register_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../subject/subject_assignment/data/subject_assignment_model.dart';

class RegisterTeacherDatasource {
  final _fsInstance = FirebaseFirestore.instance;
  final _courseInstance = FirebaseFirestore.instance.collection('courses');


  Future<bool> registerTeacher ({
    required String email,
    required String firstName,
    required String lastName,
    required List<SubjectAssignment> assignedSubjects
  })
  async{

    final docRef = _fsInstance.collection('teacher').doc(email);
    final WriteBatch batch = _fsInstance.batch();

    final assignedSubject = assignedSubjects.map((sub) {
      return AssignedSubject(
        assignmentId: sub.assignmentId,
        courseId: sub.courseId,
        semesterId: sub.semesterId,
        sectionId: sub.sectionId,
        subjectId: sub.subjectId,
        subjectName: sub.subjectName,
      );
    }).toList();

    final TeacherRegisterModel data = TeacherRegisterModel(
        teacherId: email,
        firstName: firstName,
        lastName: lastName,
        assignedSubjects: assignedSubject
    );

    try{
      docRef.set(data.toMap(), SetOptions(merge: true) );
      return true;
    }catch(e){
      return false;
    }
  }


  /// GET COURSES FROM Firestore

  Future<List<String>> getCourses() async {
    final querySnapshot = await _courseInstance.get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<bool> checkAssignmentAvailability({
    required String courseId,
    required String semesterId,
    required String subjectId,
    required String sectionId,
  }) async {
    final assignmentId = '${courseId}_${semesterId}_${subjectId}_$sectionId';
    final docRef = _fsInstance.collection('subject_assignments').doc(assignmentId);

    try {
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data()?['isAssigned'] == true) {
        return false;
      } else {
        return true;
      }
    } catch (e) {
      print('Error checking assignment availability in datasource: $e');
      // Re-throw or return false based on your error handling strategy.
      // Returning false on error ensures the UI treats it as unavailable for safety.
      throw Exception('Failed to check assignment availability: $e');
    }
  }


  Future<bool> assignSubjectToTeacher({
   required SubjectAssignment assignedSubject
  }) async {

    final docRef = _fsInstance.collection('subject_assignments').doc(assignedSubject.assignmentId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final existing = SubjectAssignment.fromDoc(docSnap);

      // If already assigned, prevent overwrite
      if (existing.isAssigned) return false;

      // Only update teacher fields
      await docRef.set({
        'teacherId': assignedSubject.teacherId,
       'teacherName': assignedSubject.teacherName,
        'isAssigned': true,
      }, SetOptions(merge: true));

    } else {
      final assignment = SubjectAssignment(
        subjectName: assignedSubject.subjectName,
        teacherName: assignedSubject.teacherName,
        assignmentId: assignedSubject.assignmentId,
        courseId: assignedSubject.courseId,
        semesterId: assignedSubject.semesterId,
        sectionId: assignedSubject.sectionId,
        subjectId: assignedSubject.subjectId,
        teacherId: assignedSubject.teacherId,
        isAssigned: assignedSubject.isAssigned,
      );

      await docRef.set({
        ...assignment.toMap(),
      });
    }

    return true;
  }

  Future<void> removeAssignedSubject ({required String? docId}) async{
    final docRef = _fsInstance.collection('subject_assignments').doc(docId);

    final removed = await docRef.delete();

    return removed;

  }


}