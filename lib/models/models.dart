class UserModel {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String consumerNumber;

  const UserModel({
    this.name = 'Irene',
    this.email = 'irene@gmail.com',
    this.phone = '9876543210',
    this.address = 'Thrissur',
    this.consumerNumber = '123456789',
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? consumerNumber,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      consumerNumber: consumerNumber ?? this.consumerNumber,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'consumer_number': consumerNumber,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] ?? '',
    address: json['address'] ?? '',
    consumerNumber: json['consumer_number'] ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          address == other.address &&
          consumerNumber == other.consumerNumber;

  @override
  int get hashCode => name.hashCode ^ email.hashCode ^ phone.hashCode ^ address.hashCode ^ consumerNumber.hashCode;
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
