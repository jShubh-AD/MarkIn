import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../subject/subject_assignment/data/subject_assignment_model.dart';

class RegisterTeacherDatasource {
  final _fsInstance = FirebaseFirestore.instance;
  final _courseInstance = FirebaseFirestore.instance.collection('courses');


  Future<bool> RegisterTeacher ({
    required String email,
    required String firstName,
    required String lastName,
  })
  async{

    final docRef = await _fsInstance.collection('teacher').doc(email).get();

    if(!docRef.exists) return false;

    try{}catch(e){}
    return true;
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
    required String courseId,
    required String semesterId,
    required String subjectId,
    required String sectionId,
    required String teacherFirstName,
    required String teacherId,
    required String teacherLastName,
  }) async {

    final assignmentId = '${courseId}_${semesterId}_${subjectId}_$sectionId';
    final docRef = _fsInstance.collection('subject_assignments').doc(assignmentId);

    final batch = _fsInstance.batch();

    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final existing = SubjectAssignment.fromDoc(docSnap);

      // If already assigned, prevent overwrite
      if (existing.isAssigned) return false;

      // Only update teacher fields
      await docRef.set({
        'teacherId': teacherId,
       'teacherName': teacherFirstName + teacherLastName,
        'isAssigned': true,
      }, SetOptions(merge: true));

    } else {
      final assignment = SubjectAssignment(
        teacherName: teacherFirstName + teacherLastName,
        assignmentId: assignmentId,
        courseId: courseId,
        semesterId: semesterId,
        sectionId: sectionId,
        subjectId: subjectId,
        teacherId: teacherId,
        isAssigned: true,
      );

      await docRef.set({
        ...assignment.toMap(),
      });
    }

    return true;
  }


}