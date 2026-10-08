class UserModel {
  final int id;
  final String name;
  final String email;
  final String type;
  final int? clinicId;
  final String? clinicName;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.clinicId,
    this.clinicName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // التعامل مع وجود المبدل user أو القراءة المباشرة
    final userData = json['user'] ?? json;

    return UserModel(
      id: userData['id'] ?? 0,
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      type: userData['type'] ?? userData['user_type'] ?? 'clinic',
      clinicId: userData['clinic_id'],
      clinicName: userData['clinic']?['name'],
    );
  }
}
