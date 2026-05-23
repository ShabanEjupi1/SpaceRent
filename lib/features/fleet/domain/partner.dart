class Partner {
  final String id;
  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final String status;
  final String subscriptionStatus; // 'Active', 'Inactive', 'Cancelled'
  final DateTime? subscriptionExpiresAt;
  final String? paypalSubscriptionId;

  Partner({
    required this.id,
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.status,
    this.subscriptionStatus = 'Inactive',
    this.subscriptionExpiresAt,
    this.paypalSubscriptionId,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      contactName: json['contact_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      status: json['status'] as String,
      subscriptionStatus: json['subscription_status'] as String? ?? 'Inactive',
      subscriptionExpiresAt: json['subscription_expires_at'] != null 
          ? DateTime.parse(json['subscription_expires_at'] as String) 
          : null,
      paypalSubscriptionId: json['paypal_subscription_id'] as String?,
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
      'subscription_status': subscriptionStatus,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'paypal_subscription_id': paypalSubscriptionId,
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
