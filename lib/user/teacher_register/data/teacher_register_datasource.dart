import 'package:attendence/user/teacher_register/data/teacher_register_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../subject/subject_assignment/data/subject_assignment_model.dart';

class RegisterTeacherDatasource {
  final _fsInstance = FirebaseFirestore.instance;
  final _courseInstance = FirebaseFirestore.instance.collection('courses');


  /// -------------------- Register Teacher Method -----------------------------


  Future<bool> registerTeacher({
    required String email,
    required String firstName,
    required String lastName,
    required List<SubjectAssignment> assignedSubjects,
    String? sheetUrl,
  }) async {
    final docRef = _fsInstance.collection('teachers').doc(email);

    try {
      final docSnapshot = await docRef.get();

      // Get existing assignedSubjects if available
      Map<String, dynamic> existingSubjects = {};

      if (!docSnapshot.exists) {
        throw Exception('No Teacher Found.');
      }

      if (docSnapshot.exists) {
        final existingData = docSnapshot.data() as Map<String, dynamic>;
        final model = TeacherRegisterModel.fromMap(existingData);
        existingSubjects = model.assignedSubjects;
      }


      // Prepare map of new assignments, only add if not already present

      final Map<String, AssignedSubject> newSubjectsMap = {};

      for (var sub in assignedSubjects) {
        newSubjectsMap[sub.assignmentId.trim()] = AssignedSubject(
          sheetUrl: sheetUrl ?? '',
          assignmentId: sub.assignmentId.trim(),
          courseId: sub.courseId,
          semesterId: sub.semesterId,
          sectionId: sub.sectionId,
          subjectId: sub.subjectId,
          subjectName: sub.subjectName,
        );
      }

      final Map<String, AssignedSubject> finalSubjects = {};

      for (var entry in existingSubjects.entries) {
        finalSubjects[entry.key] = entry.value;
      }
      for (var entry in newSubjectsMap.entries) {
        finalSubjects[entry.key] = entry.value;
      }

      // Prepare update payload
      final updatedData = TeacherRegisterModel(
        teacherId: email,
        firstName: firstName,
        lastName: lastName,
        assignedSubjects: finalSubjects,
      );

      await docRef.set(updatedData.toMap() , SetOptions(merge: true)); // 📝 1 WRITE
      return true;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }


  /// ---------------- Update Assigned Subject To the teacher ------------------

  Future<void> updateAssignedSubject(
      {
    required String email,
    required String assignedSubjectId,
    required String sheetUrl,
      }) async{

    final docRef = _fsInstance.collection('teachers').doc(email);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      throw Exception('No Teacher Found.');
    }

    // Firestore allows dot notation to update nested map fields
   await docRef.update({
      'assignedSubjects.$assignedSubjectId.sheetUrl': sheetUrl,
    });
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
    final docRef = _fsInstance.collection('subject_assignments').doc(assignmentId.trim());

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

    final docRef = _fsInstance.collection('subject_assignments').doc(assignedSubject.assignmentId.trim());
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
        assignmentId: assignedSubject.assignmentId.trim(),
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
    final docRef = _fsInstance.collection('subject_assignments').doc(docId!.trim());

    final removed = await docRef.delete();

    return removed;

  }


}