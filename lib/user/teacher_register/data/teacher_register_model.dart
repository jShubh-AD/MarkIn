class TeacherRegisterModel {
  final String teacherId;
  final String firstName;
  final String lastName;
  final Map<String, AssignedSubject> assignedSubjects;

  TeacherRegisterModel({
    required this.teacherId,
    required this.firstName,
    required this.lastName,
    required this.assignedSubjects,
  });

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'firstName': firstName,
      'lastName': lastName,
    'assignedSubjects': {for (var sub in assignedSubjects.entries) sub.key: sub.value.toMap(),}
      ,
    };
  }

  factory TeacherRegisterModel.fromMap(Map<String, dynamic> map) {

    final assignedSubjectsMap = Map<String, dynamic>.from(map['assignedSubjects'] ?? {});

    return TeacherRegisterModel(
      teacherId: map['teacherId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      assignedSubjects: {
        for (var entry in assignedSubjectsMap.entries)
          entry.key: AssignedSubject.fromMap(Map<String, dynamic>.from(entry.value)),
      },
    );
  }
}





class AssignedSubject {
  final String assignmentId;
  final String courseId;
  final String semesterId;
  final String sectionId;
  final String subjectId;
  final String subjectName;
  final String? sheetUrl;

  AssignedSubject({
    required this.assignmentId,
    required this.courseId,
    required this.semesterId,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
    required this.sheetUrl
  });

  // From Firestore/JSON
  factory AssignedSubject.fromMap(Map<String, dynamic> map) {
    return AssignedSubject(
      sheetUrl: map['sheetUrl'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      courseId: map['courseId'] ?? '',
      semesterId: map['semesterId'] ?? '',
      sectionId: map['sectionId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
    );
  }

  // To Firestore/JSON
  Map<String, dynamic> toMap() {
    return {
      'sheetUrl': sheetUrl,
      'assignmentId': assignmentId,
      'courseId': courseId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
    };
  }
}
