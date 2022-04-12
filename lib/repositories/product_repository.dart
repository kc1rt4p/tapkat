import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapkat/models/decode_param.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/product_type.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/store_like.dart';
import 'package:tapkat/models/upload_product_image_response.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/utilities/application.dart' as application;

void decodeIsolate(DecodeParam param) {
  var image = decodeImage(param.file.readAsBytesSync())!;
  var thumbnail = copyResizeCropSquare(image, 300);
  param.sendPort.send(thumbnail);
}

class ProductRepository {
  final _apiService = ApiService();

  Future<List<LikedProductModel>> getUserFavourites(String userId) async {
    final response =
        await _apiService.post(url: 'users/likes/searchfirst', body: {
      "psk": psk,
      "userid": userId,
      "productcount": productCount,
    });

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['like_list'] as List<dynamic>)
        .map((json) => LikedProductModel.fromJson(json))
        .toList();
  }

  Future<List<ProductModel>> getnextuserFavourites(
      String userId, String lastProductId, String lastProductDate) async {
    final response =
        await _apiService.post(url: 'users/likes/searchset', body: {
      "psk": psk,
      "userid": userId,
      "productcount": productCount,
      "startaferval": lastProductDate,
      "productid": lastProductId,
    });

    return (response.data['like_list'] as List<dynamic>)
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

  Future<bool> addProductReview(ProductReviewModel productReview) async {
    final response = await _apiService.post(
      url: 'products/review',
      body: {
        "psk": "lcp9321p",
        ...productReview.toJson(),
      },
    );

    return response.data['status'] == 'SUCCESS';
  }

  Future<ProductReviewModel?> getProductReview(
      String productId, String userId) async {
    final response = await _apiService.post(
      url: 'products/review/get',
      body: {
        'psk': psk,
        'userid': userId,
        'productid': productId,
      },
    );

    if (response.data['status'] == 'SUCCESS')
      return ProductReviewModel.fromJson(response.data['products']);

    return null;
  }

  Future<bool> updateProductReview(ProductReviewModel productReview) async {
    final response =
        await _apiService.patch(url: 'products/review/update', body: {
      'psk': psk,
      ...productReview.toJson(),
    });

    return response.data['status'] == 'SUCCESS';
  }

  Future<UploadProductImageResponseModel?> addProductImages({
    required String productId,
    required String userId,
    required List<SelectedMedia> images,
  }) async {
    var formData = FormData.fromMap({
      "psk": "lcp9321p",
      'userid': userId,
      'productid': productId,
    });

    List<SelectedMedia> _imgsToUpload = [];

    for (var img in images) {
      var receivePort = ReceivePort();
      await Isolate.spawn(
          decodeIsolate, DecodeParam(File(img.rawPath!), receivePort.sendPort));

      // Get the processed image from the isolate.
      var image = await receivePort.first as Image;

      final fileName = img.fileName.split('.')[0] + '_t.jpg';

      Directory appDocDirectory = await getApplicationDocumentsDirectory();

      final thumbnail = await File(appDocDirectory.path + '/' + fileName)
          .writeAsBytes(encodeJpg(image));

      _imgsToUpload.addAll([
        img,
        SelectedMedia(fileName, thumbnail.path, thumbnail.readAsBytesSync(),
            appDocDirectory.path + '/' + fileName),
      ]);
    }

    for (var img in _imgsToUpload) {
      final mimeType = mime(img.fileName);
      String mimee = mimeType!.split('/')[0];
      String type = mimeType.split('/')[1];

      if (img.rawPath == null) continue;

      formData.files.add(
        MapEntry(
          'media',
          MultipartFile.fromFileSync(
            img.rawPath!,
            contentType: MediaType(mimee, type),
          ),
        ),
      );
    }

    print('ready to upload: ${formData.files.length}');

    final response = await _apiService.post(
      url: 'products/upload',
      formData: formData,
    );

    if (response.data['status'] != 'SUCCESS') return null;

    return UploadProductImageResponseModel.fromJson(response.data);
  }

  Future<List<ProductReviewModel>> getProductRatings({
    String? productId,
    String? userId,
  }) async {
    final response = await _apiService.post(
      url: 'products/review/searchfirst',
      body: {
        'psk': psk,
        productId != null ? 'productid' : 'userid': productId ?? userId,
        'sortby': 'date',
        'sortdirection': 'descending',
        'productcount': 10,
      },
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>)
        .map((d) => ProductReviewModel.fromJson(d))
        .toList();
  }

  Future<List<ProductReviewModel>> getNextRatings({
    String? productId,
    String? userId,
    required String secondaryVal,
    required String startAfterVal,
  }) async {
    final response = await _apiService.post(
      url: 'products/review/searchSet',
      body: {
        'psk': psk,
        productId != null ? 'productid' : 'userid': productId ?? userId,
        'sortby': 'date',
        'sortdirection': 'descending',
        'productcount': 10,
        'startafterval': startAfterVal,
        'secondaryval': secondaryVal,
      },
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>)
        .map((d) => ProductReviewModel.fromJson(d))
        .toList();
  }

  Future<List<ProductModel>> getNextProducts({
    required String listType,
    String? userId,
    required String lastProductId,
    required dynamic startAfterVal,
    List<String>? interests,
    LocationModel? location,
    int radius = 5000,
  }) async {
    var body = {
      'psk': psk,
      'userid': userId,
      'productcount': productCount,
    };

    if (location != null) {
      body.addAll({
        'startafterval': startAfterVal,
        'location': location.toJson(),
        'radius': radius,
      });
    }

    if (listType == 'demand') {
    } else {
      body.addAll({
        'sortBy': 'price',
        'startafterval': double.parse(startAfterVal),
        'productid': lastProductId,
      });
    }

    final response = await _apiService.post(
      url: 'products/$listType/searchset',
      body: body,
    );

    if (response.data['status'] == 'FAIL') return [];

    return (response.data['products'] as List<dynamic>).map((json) {
      return ProductModel.fromJson(json);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllCategoryProducts() async {
    final data = await getProductRefData();
    if (data == null) return [];
    final categories = data['categories'] as List<ProductCategoryModel>;
    print("=== === === ${categories.length}");
    List<Map<String, dynamic>> list = [];

    for (var cat in categories.where((cat) => cat.type == 'PT1')) {
      list.add({
        'name': cat.name,
        'code': cat.code,
        'products': await getCategoryProducts(cat.code!),
      });
    }

    return list;
  }

  Future<List<ProductModel>> getCategoryProducts(String category,
      [String? userid]) async {
    var _body = {
      'psk': psk,
      'sortby': 'price',
      'type': 'PT1',
      'category': category,
      'sortdirection': 'ascending',
      'productcount': productCount,
      'location': application.currentUserLocation!.toJson(),
    };

    final response = await _apiService.post(
      url: 'products/searchfirst',
      body: _body,
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<List<ProductModel>> getFirstProducts(
      String listType, LocationModel? location, int? radius,
      [String? userid, List<String>? interests]) async {
    var body = {
      'psk': psk,
      'userid': userid,
      'productcount': productCount,
    };

    if (location != null && listType != 'user') {
      body.addAll({
        'location': location.toJson(),
        'radius': radius ?? 5000,
      });
    }

    if (listType != 'demand') {
      body.addAll({
        'sortby': 'price',
        'sortdirection': listType == 'reco' ? 'ascending' : 'descending',
      });

      if (listType == 'reco' && interests != null) {
        body.addAll({'interests': interests});
      }
    }
    final response = await _apiService.post(
      url: 'products/$listType/searchfirst',
      body: body,
      // params: userid != null
      //     ? {
      //         'userid': userid,
      //       }
      //     : null,
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

  Future<Map<String, dynamic>?> getProductRefData() async {
    final response = await _apiService.get(url: 'reference/productref');

    if (response.data['status'] != 'SUCCESS') return null;

    return {
      'categories': (response.data['product reference data']['categories']
              as List<dynamic>)
          .map((data) => ProductCategoryModel.fromJson(data))
          .toList(),
      'types':
          (response.data['product reference data']['types'] as List<dynamic>)
              .map((data) => ProductTypeModel.fromJson(data))
              .toList(),
    };
  }

  Future<bool> updateProduct(ProductRequestModel product) async {
    final response = await _apiService.post(
      url: 'products/update/${product.productid}',
      body: {
        'psk': psk,
        ...product.toJson(updating: true),
      },
    );

    return response.data['status'] == 'SUCCESS';
  }

  Future<bool> deleteImages(
      List<String> urls, String userId, String productId) async {
    var body = {
      'psk': psk,
      'userid': userId,
      'productid': productId,
    };

    if (urls.length > 0) {
      urls.asMap().forEach((key, value) {
        body.addAll({
          'media${key + 1}': value,
        });
      });
    }

    final response = await _apiService.post(
      url: 'products/delete',
      body: body,
    );

    if (response.data['status'] != 'SUCCESS') return false;

    return true;
  }

  Future<List<ProductModel>> searchProducts(List<String> keyword,
      {String? lastProductId,
      String? startAfterVal,
      String? category,
      required String sortBy,
      required LocationModel location,
      int radius = 5000}) async {
    var _body = {
      'psk': psk,
      'sortby': sortBy.toLowerCase(),
      'sortdirection': 'ascending',
      'productcount': productCount,
      'userid': application.currentUser!.uid,
      'location': location.toJson(),
      'radius': radius,
    };
    if (keyword.length > 0) _body.addAll({'keywords': keyword});
    if (category != null) _body.addAll({'category': category});
    if (lastProductId != null && startAfterVal != null) {
      _body.addAll({
        'startafterval': double.parse(startAfterVal),
        'productid': lastProductId,
      });
    }
    final response = await _apiService.post(
      url:
          'products/${(lastProductId != null && startAfterVal != null) ? 'searchset' : 'searchfirst'}',
      body: _body,
    );

    if (response.data['status'] != 'SUCCESS') return [];

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

  Future<bool> addRating({
    required ProductRequestModel productRequest,
    required String userId,
    required double rating,
  }) async {
    final response = await _apiService.post(
      url: 'products/update/${productRequest.productid}',
      body: {
        'psk': psk,
        ...productRequest.toJson(updating: true),
        'rating': rating,
      },
    );

    return response.data['status'] == 'SUCCESS';
  }

  Future<bool> likeProduct({
    required ProductRequestModel productRequest,
    required String userId,
    required int like,
  }) async {
    // final _productRef = FirebaseFirestore.instance.collection('user_likes');
    final response = await _apiService.post(
      url: 'products/like',
      body: {
        'psk': psk,
        'productid': productRequest.productid,
        'productname': productRequest.productname,
        'userid': userId,
        'like': like,
        'price': productRequest.price,
        'image_url': productRequest.image_url,
      },
    );
    print(response.data['status']);

    return response.data['status'] == 'SUCCESS';
  }
}
