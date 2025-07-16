import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterStudentService {
  final ffInstance = FirebaseFirestore.instance.collection('students');

  Future<bool> registerStudents({
    required String email,
    required String name,
    required String roll,
    required String course,
    required String section,
}) async{
    final docRef = ffInstance.doc(roll.trim());
    final doc = await docRef.get();

    if (!doc.exists) return false;

    await docRef.update({
      'name': name,
      'course': course,
      'section': section,
      'email': email,
      'role': 'student',
      'updated_time': FieldValue.serverTimestamp(),
    });

    return true;
  }
}