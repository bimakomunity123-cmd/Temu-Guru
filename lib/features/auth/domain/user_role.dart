enum UserRole {
  student,
  teacher,
  admin,
}

enum TeacherApplicationStatus {
  pending,
  approved,
  rejected,
}

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final TeacherApplicationStatus? teacherStatus;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.teacherStatus,
    this.rejectionReason,
    this.reviewedAt,
  });

  bool get isStudent => role == UserRole.student;
  bool get isTeacher => role == UserRole.teacher;
  bool get isAdmin => role == UserRole.admin;
  bool get isTeacherApproved =>
      isTeacher && teacherStatus == TeacherApplicationStatus.approved;
  bool get isTeacherPending =>
      isTeacher && teacherStatus == TeacherApplicationStatus.pending;
  bool get isTeacherRejected =>
      isTeacher && teacherStatus == TeacherApplicationStatus.rejected;

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    TeacherApplicationStatus? teacherStatus,
    String? rejectionReason,
    DateTime? reviewedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      teacherStatus: teacherStatus ?? this.teacherStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
