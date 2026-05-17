class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.aadhaarNumber,
    this.panNumber,
    this.emailVerified = false,
    this.faceRegistered = false,
    this.faceVerificationRequired = false,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String? address;
  final String? dateOfBirth;
  final String? aadhaarNumber;
  final String? panNumber;
  final bool emailVerified;
  final bool faceRegistered;
  final bool faceVerificationRequired;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: '${json['id'] ?? json['_id'] ?? ''}',
      name:
          '${json['name'] ?? json['full_name'] ?? json['student_name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      avatarUrl:
          json['avatar']?.toString() ??
          json['profile_photo_url']?.toString() ??
          json['profile_image_url']?.toString() ??
          json['profile_image']?.toString(),
      phone: json['phone']?.toString() ?? json['mobile']?.toString(),
      address: json['address']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      aadhaarNumber:
          json['aadhaar_no']?.toString() ?? json['adhaar_no']?.toString(),
      panNumber: json['pan_no']?.toString(),
      emailVerified:
          json['email_verified'] == true ||
          json['email_verification']?.toString() == '1',
      faceRegistered:
          json['face_registered'] == true || json['is_face_registered'] == true,
      faceVerificationRequired: json['face_verification_required'] == true,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? phone,
    String? address,
    String? dateOfBirth,
    String? aadhaarNumber,
    String? panNumber,
    bool? emailVerified,
    bool? faceRegistered,
    bool? faceVerificationRequired,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      panNumber: panNumber ?? this.panNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      faceRegistered: faceRegistered ?? this.faceRegistered,
      faceVerificationRequired:
          faceVerificationRequired ?? this.faceVerificationRequired,
    );
  }
}
