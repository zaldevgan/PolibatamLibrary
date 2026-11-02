import 'dart:convert';

class UserProfile {
  final String memberId; // NIM atau NIP
  final String name;
  final String email;
  final String? programStudi;
  final String? memberType;
  final String? phone;
  final String? expireDate;
  final String? rfid;

  UserProfile({
    required this.memberId,
    required this.name,
    required this.email,
    this.programStudi,
    this.memberType,
    this.phone,
    this.expireDate,
    this.rfid,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      memberId: json['member_id']?.toString() ?? '',
      name: json['member_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['member_email']?.toString() ?? json['email']?.toString() ?? '',
      programStudi: json['program_studi']?.toString(),
      memberType: json['member_type_name']?.toString(),
      phone: json['member_phone']?.toString() ?? json['phone']?.toString(),
      expireDate: json['expire_date']?.toString(),
      rfid: json['rfid']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'name': name,
      'email': email,
      'program_studi': programStudi,
      'member_type_name': memberType,
      'phone': phone,
      'expire_date': expireDate,
      'rfid': rfid,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserProfile.fromJsonString(String source) =>
      UserProfile.fromJson(jsonDecode(source));
}

