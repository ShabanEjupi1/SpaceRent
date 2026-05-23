class Vehicle {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String transmission; // 'Automatic', 'Manual'
  final String fuelType; // 'Diesel', 'Petrol', 'Electric', 'Hybrid'
  final bool hasAc;
  final double pricePerDay;
  final String imageUrl;
  final String locationId;
  final String? partnerId;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.transmission,
    required this.fuelType,
    required this.hasAc,
    required this.pricePerDay,
    required this.imageUrl,
    required this.locationId,
    this.partnerId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      transmission: json['transmission'] as String,
      fuelType: json['fuel_type'] as String,
      hasAc: json['has_ac'] as bool,
      pricePerDay: (json['price_per_day'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      locationId: json['location_id'] as String,
      partnerId: json['partner_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'transmission': transmission,
      'fuel_type': fuelType,
      'has_ac': hasAc,
      'price_per_day': pricePerDay,
      'image_url': imageUrl,
      'location_id': locationId,
      'partner_id': partnerId,
    };
  }
}
