import 'package:tapkat/models/product.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/constants.dart';

class ProductRepository {
  final _apiService = ApiService();

  Future<ProductModel> getProduct(String id) async {
    final response = await _apiService.get(url: 'products/single/$id');

    return ProductModel.fromJson(response.data);
  }

  Future<bool> addProduct(ProductModel product) async {
    final response = await _apiService.post(
      url: 'products',
      body: product.toJson(),
    );

    return response.data['status'] == 'success';
  }

  Future<List<ProductModel>> getAllProducts(
      String listType, String userid) async {
    final response = await _apiService.post(
      url: 'products/$listType/searchfirst',
      body: {
        'userid': userid,
        'productcount': productCount,
        'sortBy': 'price',
        'sortdirection': 'descending',
      },
    );

    if (response.data['status'] != 'success') return [];

    return (response.data['products'] as List<dynamic>)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<bool> deleteProduct(String id) async {
    final response = await _apiService.delete(url: 'products/$id');

    return response.data['status'] == 'success';
  }

  Future<bool> updateProduct(ProductModel product) async {
    final response = await _apiService.post(
      url: 'products/update/${product.productid}',
      body: product.toJson(),
    );

    return response.data['status'] == 'success';
  }

  Future<List<ProductModel>> searchProducts(String keyword) async {
    final response = await _apiService.post(
      url: 'products/user/searchfirst',
      body: {
        'psk': psk,
        'keywords': [
          keyword,
        ],
        'sortby': 'price',
        'sortDirection': 'ascending',
      },
    );

    if ((response.data['status'] as String).toLowerCase() != 'success')
      return [];

    return (response.data['products'] as List<dynamic>)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<bool> addToWishList(String productId, String userId) async {
    final response = await _apiService.post(url: 'products/wishlist', body: {
      'userid': userId,
      'productid': productId,
    });

    return response.data['status'] == 'success';
  }
}
