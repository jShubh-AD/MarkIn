import 'package:cloud_firestore/cloud_firestore.dart';

import '../../user/teacher_register/data/teacher_register_model.dart';

class TeacherDashboardDatasource {
  final _fsInstance = FirebaseFirestore.instance;

  Future<TeacherRegisterModel?> getTeacherData(String email) async {
    try {
      final doc = await _fsInstance.collection('teachers').doc(email).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return TeacherRegisterModel.fromMap(data);
        } else {
          throw Exception('No data for $email');
        }
      } else {
        throw Exception('No teacher found with email: $email');
      }
    } on FirebaseException catch (e) {
      throw Exception('FirebaseException while fetching teacher data: ${e.message}');
    } catch (e, stackTrace) {
      throw Exception('Unexpected error in getTeacherData: $e');
    }
  }


}