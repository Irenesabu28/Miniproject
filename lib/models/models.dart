class UserModel {
  final String name;
  final String email;
  final String phone;

  const UserModel({
    this.name = '',
    this.email = '',
    this.phone = '',
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          phone == other.phone;

  @override
  int get hashCode => name.hashCode ^ email.hashCode ^ phone.hashCode;
}

class TripLog {
  final DateTime timestamp;
  final bool isTripped;
  final String description;

  const TripLog({
    required this.timestamp,
    required this.isTripped,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripLog &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          isTripped == other.isTripped &&
          description == other.description;

  @override
  int get hashCode => timestamp.hashCode ^ isTripped.hashCode ^ description.hashCode;
}
