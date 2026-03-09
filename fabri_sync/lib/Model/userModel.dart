// class UserModel {
//   final String uid;
//   final String name;
//   final String email;
//   final String phoneNumber;

//   UserModel({
//     required this.uid,
//     required this.name,
//     required this.email,
//     required this.phoneNumber,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'uid': uid,
//       'name': name,
//       'email': email,
//       'phoneNumber': phoneNumber,
//     };
//   }

//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       uid: json['uid'] ?? '',
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       phoneNumber: json['phoneNumber'] ?? '',
//     );
//   }

//   @override
//   String toString() {
//     return 'UserModel(uid: $uid, name: $name, email: $email, phone: $phoneNumber)';
//   }
// }
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String role;
  final String? department;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'manager',
      department: json['department'], // nullable ✔
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'department': department,
    };
  }
}
