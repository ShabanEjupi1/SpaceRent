class Booking {
  final String id;
  final String vehicleId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // 'Pending', 'Confirmed', 'Cancelled', 'Rejected'
  final String? fullName;
  final String? phoneNumber;
  final String? emailAddress;
  final String? language; // 'en' or 'sq' — user locale at booking time
  final String paymentStatus; // 'Unpaid', 'Paid'
  final String? paypalOrderId;
  final DateTime? paidAt;
  final String paymentMethod; // 'Online', 'Cash'

  Booking({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.fullName,
    this.phoneNumber,
    this.emailAddress,
    this.language,
    this.paymentStatus = 'Unpaid',
    this.paypalOrderId,
    this.paidAt,
    this.paymentMethod = 'Online',
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      emailAddress: json['email_address'] as String?,
      language: json['language'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'Unpaid',
      paypalOrderId: json['paypal_order_id'] as String?,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      paymentMethod: json['payment_method'] as String? ?? 'Online',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_price': totalPrice,
      'status': status,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'email_address': emailAddress,
      'language': language ?? 'en',
      'payment_status': paymentStatus,
      'paypal_order_id': paypalOrderId,
      'paid_at': paidAt?.toIso8601String(),
      'payment_method': paymentMethod,
    };
  }
}
