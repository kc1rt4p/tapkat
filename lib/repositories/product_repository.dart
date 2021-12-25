import 'package:dio/dio.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/models/upload_product_image_response.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/upload_media.dart';

class ProductRepository {
  final _apiService = ApiService();

  Future<List<ProductModel>> getUserFavourites(String userId) async {
    final response = await _apiService.get(
      url: 'users/likes/$userId',
    );

    print('===== RESPONSE: $response');

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['like_list'] as List<Map<String, dynamic>>)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<ProductModel> getProduct(String id) async {
    final response = await _apiService.get(url: 'products/single/$id');

    return ProductModel.fromJson(response.data);
  }

  Future<String?> addProduct(ProductRequestModel product) async {
    final response = await _apiService.post(
      url: 'products',
      body: {
        "psk": "lcp9321p",
        ...product.toJson(),
      },
    );

    if (response.data['status'] != 'SUCCESS') return null;

    return response.data['productid'] as String;
  }

  Future<UploadProductImageResponseModel?> addProductImages({
    required String productId,
    required String userId,
    required List<SelectedMedia> images,
  }) async {
    print('no. images to upload: ${images.length}');

    var formData = FormData.fromMap({
      "psk": "lcp9321p",
      'userid': userId,
      'productid': productId,
      'primary_media': images.first.fileName,
    });

    images.forEach(
      (img) => formData.files.add(
        MapEntry(
          'media',
          MultipartFile.fromFileSync(img.rawPath!),
        ),
      ),
    );

    final response = await _apiService.post(
      url: 'products/upload',
      formData: formData,
      onSendProgress: (sent, total) {
        print('sent: $sent == total: $total');
      },
      header: {
        'Content-Type': 'multipart/form-data',
      },
    );

    print('formData fields: ${formData.fields}');
    print('formData files: ${formData.files}');

    if (response.data['status'] == 'SUCCESS') return null;

    return UploadProductImageResponseModel.fromJson(response.data);
  }

  Future<List<ProductModel>> getNextProducts({
    required String listType,
    String? userId,
    required String lastProductId,
    required String startAfterVal,
  }) async {
    final response =
        await _apiService.post(url: 'products/$listType/searchSet', body: {
      'psk': psk,
      'userid': userId,
      'productcount': productCount,
      'sortBy': 'price',
      'startafterval': startAfterVal,
      'productid': lastProductId,
    });

    return (response.data['products'] as List<dynamic>).map((json) {
      return ProductModel.fromJson(json);
    }).toList();
  }

  Future<List<ProductModel>> getFirstProducts(
      String listType, String? userid) async {
    final response = await _apiService.post(
      url: 'products/$listType/searchfirst',
      body: {
        'psk': psk,
        'userid': userid,
        'productcount': productCount,
        'sortBy': 'price',
        'sortdirection': listType == 'reco' ? 'ascending' : 'descending',
      },
      params: {
        'userid': userid,
      },
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>).map((json) {
      return ProductModel.fromJson(json);
    }).toList();
  }

  Future<bool> deleteProduct(String id) async {
    final response = await _apiService.delete(url: 'products/$id');

    return response.data['status'] == 'SUCCESS';
  }

  Future<bool> updateProduct(ProductModel product) async {
    final response = await _apiService.post(
      url: 'products/update/${product.productid}',
      body: {
        'psk': psk,
        ...product.toJson(),
      },
    );

    return response.data['status'] == 'SUCCESS';
  }

  Future<List<ProductModel>> searchProducts(List<String> keyword) async {
    final response = await _apiService.post(
      url: 'products/searchfirst',
      body: {
        'psk': psk,
        'keywords': keyword,
        'sortby': 'price',
        'sortDirection': 'ascending',
        'productcount': productCount,
      },
    );

    if ((response.data['status'] as String).toLowerCase() != 'SUCCESS')
      return [];

    return (response.data['products'] as List<dynamic>)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<bool> addToWishList(String productId, String userId) async {
    final response = await _apiService.post(url: 'products/wishlist', body: {
      'userid': userId,
      'productid': productId,
      'psk': psk,
    });

    return response.data['status'] == 'SUCCESS';
  }

  Future<bool> addLike({
    required ProductRequestModel productRequest,
    required String userId,
  }) async {
    final response = await _apiService.post(
      url: 'products/update/${productRequest.productid}',
      body: {
        'psk': psk,
        ...productRequest.toJson(updating: true),
        'like': 1,
      },
    );

    return response.data['status'] == 'SUCCESS';
  }
}
