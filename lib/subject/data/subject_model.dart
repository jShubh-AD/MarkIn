class SubjectModel {
  final String subjectCode;
  final String subjectName;

  SubjectModel({
    required this.subjectCode,
    required this.subjectName,
  });

  // Convert Firestore data to SubjectModel
  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      subjectCode: map['subject_code'] ?? '',
      subjectName: map['subject_name'] ?? '',
    );
  }

  // Convert SubjectModel to Map for uploading to Firestore

  Map<String, dynamic> toMap() {
      return {
        'subject_code': subjectCode,
        'subject_name': subjectName,
      };
  }
}







