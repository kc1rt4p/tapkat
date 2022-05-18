class LocalizationModel {
  final String? country_code;
  final String? country;
  final String? currency;

  LocalizationModel({
    this.country,
    this.country_code,
    this.currency,
  });

  factory LocalizationModel.fromJson(Map<String, dynamic> json) {
    return LocalizationModel(
      country: json['country'] as String?,
      country_code: json['country_code'] as String?,
      currency: json['currency'] as String?,
    );
  }
}
