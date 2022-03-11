class ProductCategoryModel {
  final String? code;
  final String? name;

  ProductCategoryModel({
    this.code,
    this.name,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
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
