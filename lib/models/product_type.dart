class ProductTypeModel {
  final String? code;
  final String? name;

  ProductTypeModel({
    this.code,
    this.name,
  });

  factory ProductTypeModel.fromJson(Map<String, dynamic> json) {
    return ProductTypeModel(
      code: json['code'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': this.code,
      'name': this.name,
    };
  }
}
