class Location {
  final String id;
  final String nameEn;
  final String nameSq;
  final String nameSr;
  final String code;

  Location({
    required this.id,
    required this.nameEn,
    required this.nameSq,
    required this.nameSr,
    required this.code,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameSq: json['name_sq'] as String,
      nameSr: json['name_sr'] as String,
      code: json['code'] as String,
    );
  }

  String getLocalizedName(String languageCode) {
    switch (languageCode) {
      case 'sq':
        return nameSq;
      case 'sr':
        return nameSr;
      default:
        return nameEn;
    }
  }
}
