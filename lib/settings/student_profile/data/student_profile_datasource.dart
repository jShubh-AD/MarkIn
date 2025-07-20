import 'package:attendence/user/register/data/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../subject/data/subject_model.dart';

class StudentProfileDatasource {
  final fbInstance = FirebaseFirestore.instance.collection('students');

  Future<StudentModel?> getStudentData (String? roll) async {
    if (roll == null) return null;
    final doc = await fbInstance.doc(roll).get();

    if (doc.exists) {
      return StudentModel.fromFirestore(doc);
    } else {
      return null;
    }
  }

  Future<List<SubjectModel>> getStudentSubjects({
    required String roll
  }) async {
    final attendanceCollection = fbInstance.doc(roll).collection('attendance');

    final querySnapshot = await attendanceCollection.get();

    return querySnapshot.docs
        .map((doc) => SubjectModel.fromMap(doc.data()))
        .toList();
  }

}