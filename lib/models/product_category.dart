class ProductCategoryModel {
  final String? code;
  final String? name;
  final String? type;

  ProductCategoryModel({
    this.code,
    this.name,
    this.type,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      code: json['code'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': this.code,
      'name': this.name,
      'type': this.type,
    };
  }
}
