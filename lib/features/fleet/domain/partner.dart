class Partner {
  final String id;
  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final String status;

  Partner({
    required this.id,
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      contactName: json['contact_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'contact_name': contactName,
      'email': email,
      'phone': phone,
      'status': status,
    };
  }
}

class PartnerApplication {
  final String id;
  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final String status;
  final String? inviteToken;

  PartnerApplication({
    required this.id,
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.status,
    this.inviteToken,
  });

  factory PartnerApplication.fromJson(Map<String, dynamic> json) {
    return PartnerApplication(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      contactName: json['contact_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      status: json['status'] as String,
      inviteToken: json['invite_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'contact_name': contactName,
      'email': email,
      'phone': phone,
      'status': status,
      'invite_token': inviteToken,
    };
  }
}
