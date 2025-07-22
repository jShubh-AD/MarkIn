
class TeacherRegisterModel {
  final String teacherId;
  final String firstName;
  final String lastName;
  final List<AssignedSubject> assignedSubjects;

  TeacherRegisterModel({
    required this.teacherId,
    required this.firstName,
    required this.lastName,
    required this.assignedSubjects,
  });

  // From Firestore/JSON
  factory TeacherRegisterModel.fromMap(Map<String, dynamic> map) {
    return TeacherRegisterModel(
      teacherId: map['teacherId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      assignedSubjects: (map['assignedSubjects'] as List<dynamic>?)
          ?.map((e) => AssignedSubject.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // To Firestore/JSON
  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'firstName': firstName,
      'lastName': lastName,
      'assignedSubjects': assignedSubjects.map((e) => e.toMap()).toList(),
    };
  }
}





class AssignedSubject {
  final String assignmentId;
  final String courseId;
  final String semesterId;
  final String sectionId;
  final String subjectId;
  final String subjectName;

  AssignedSubject({
    required this.assignmentId,
    required this.courseId,
    required this.semesterId,
    required this.sectionId,
    required this.subjectId,
    required this.subjectName,
  });

  // From Firestore/JSON
  factory AssignedSubject.fromMap(Map<String, dynamic> map) {
    return AssignedSubject(
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
      'assignmentId': assignmentId,
      'courseId': courseId,
      'semesterId': semesterId,
      'sectionId': sectionId,
      'subjectId': subjectId,
      'subjectName': subjectName,
    };
  }
}
