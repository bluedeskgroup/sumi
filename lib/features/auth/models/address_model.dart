class AddressModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final bool isDefault;
  final DateTime createdAt;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.postalCode,
    required this.country,
    this.isDefault = false,
    required this.createdAt,
  });

  AddressModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AddressModel.fromMap(String id, Map<String, dynamic> data) {
    return AddressModel(
      id: id,
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      addressLine1: data['addressLine1'] ?? '',
      addressLine2: data['addressLine2'],
      city: data['city'] ?? '',
      state: data['state'],
      postalCode: data['postalCode'],
      country: data['country'] ?? '',
      isDefault: data['isDefault'] ?? false,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}


