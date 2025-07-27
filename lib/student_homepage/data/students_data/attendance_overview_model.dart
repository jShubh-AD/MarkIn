import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceOverviewModel {
  final bool isOpen;
  final String attendanceCode;
  final Timestamp? expTime;
  final String sheetUrl;

  AttendanceOverviewModel({
    required this.isOpen,
    required this.sheetUrl,
    required this.expTime,
    required this.attendanceCode,
  });

  factory AttendanceOverviewModel.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    if (rawData == null) {
      throw Exception('Attendance document does not exist or is empty.');
    }

    final data = rawData as Map<String, dynamic>;

    return AttendanceOverviewModel(
      sheetUrl:  data['sheetUrl'] ?? '',
      attendanceCode: data['code'] ?? '',
      isOpen: data['isOpen'] ?? false,
      expTime: data['expTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sheetUrl': sheetUrl,
      'isOpen': isOpen,
      'expTime': expTime,
      'code': attendanceCode,
    };
  }
}
