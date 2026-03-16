class UserModel {
  String name;
  String email;
  String phone;
  String address;
  String consumerNumber; // Maps to consumer_number in JSON

  UserModel({
    this.name = 'Irene',
    this.email = 'irene@gmail.com',
    this.phone = '9876543210',
    this.address = 'Thrissur',
    this.consumerNumber = '123456789',
  });

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
}

class TripLog {
  final DateTime timestamp;
  final bool isTripped;
  final String description;

  TripLog({
    required this.timestamp,
    required this.isTripped,
    required this.description,
  });
}
