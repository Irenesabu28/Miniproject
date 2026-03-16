class UserModel {
  String name;
  String phone;
  String address;
  String consumerNumber;

  UserModel({
    this.name = 'Irene Sabu',
    this.phone = '+91 9876543210',
    this.address = '123, Green Valley, Kerala, India',
    this.consumerNumber = 'ELCB-7788-2026',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'consumerNumber': consumerNumber,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    address: json['address'] ?? '',
    consumerNumber: json['consumerNumber'] ?? '',
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
