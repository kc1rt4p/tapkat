import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapkat/models/decode_param.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/models/upload_product_image_response.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/upload_media.dart';

void decodeIsolate(DecodeParam param) {
  var image = decodeImage(param.file.readAsBytesSync())!;
  var thumbnail = copyResizeCropSquare(image, 300);
  param.sendPort.send(thumbnail);
}

class ProductRepository {
  final _apiService = ApiService();

  Future<List<ProductModel>> getUserFavourites(String userId) async {
    final response = await _apiService.get(
      url: 'users/likes/$userId',
    );

    if (response.data['status'] != 'SUCCESS') return [];

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

      print('==== scaling image ====');
      await Isolate.spawn(
          decodeIsolate, DecodeParam(File(img.rawPath!), receivePort.sendPort));
      print('==== done scaling ====');

      // Get the processed image from the isolate.
      var image = await receivePort.first as Image;

      final fileName = img.fileName.split('.')[0] + '_t.jpg';

      Directory appDocDirectory = await getApplicationDocumentsDirectory();

      final thumbnail = await File(appDocDirectory.path + '/' + fileName)
          .writeAsBytes(encodeJpg(image));

      print('thumbnail width: ${image.width}');
      print('original file size: ${await File(img.rawPath!).length()}');
      print('thumbnail file size: ${await thumbnail.length()}');

      _imgsToUpload.addAll([
        img,
        SelectedMedia(fileName, thumbnail.path, thumbnail.readAsBytesSync(),
            appDocDirectory.path + '/' + fileName),
      ]);
    }

    // images.forEach((img) async {
    //   var receivePort = ReceivePort();
    //   print('==== scaling image ====');
    //   await Isolate.spawn(
    //       decodeIsolate, DecodeParam(File(img.rawPath!), receivePort.sendPort));

    //   print('==== done scaling ====');

    //   // var decodedImage = decodeImage(img.bytes)!;
    //   // var resizedImage = copyResize(decodedImage, width: 120);

    //   // Get the processed image from the isolate.
    //   var image = await receivePort.first as Image;
    //   final fileName = img.fileName.split('.')[0] + '_t.png';

    //   Directory appDocDirectory = await getApplicationDocumentsDirectory();

    //   final thumbnail = await File(appDocDirectory.path + '/' + fileName)
    //       .writeAsBytes(encodePng(image));

    //   images.add(
    //       SelectedMedia(fileName, thumbnail.path, thumbnail.readAsBytesSync()));
    // });

    print('no. of images to upload: ${_imgsToUpload.length}');

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

    // _imgsToUpload.forEach((img) {
    //   final mimeType = mime(img.fileName);
    //   String mimee = mimeType!.split('/')[0];
    //   String type = mimeType.split('/')[1];

    //   print(img.storagePath);

    //   formData.files.add(
    //     MapEntry(
    //       'media',
    //       MultipartFile.fromFileSync(
    //         img.rawPath!,
    //         contentType: MediaType(mimee, type),
    //       ),
    //     ),
    //   );
    // });

    final response = await _apiService.post(
      url: 'products/upload',
      formData: formData,
    );

    if (response.data['status'] != 'SUCCESS') return null;

    return UploadProductImageResponseModel.fromJson(response.data);
  }

  Future<List<ProductModel>> getNextProducts({
    required String listType,
    String? userId,
    required String lastProductId,
    required String startAfterVal,
  }) async {
    final response =
        await _apiService.post(url: 'products/$listType/searchset', body: {
      'psk': psk,
      'userid': userId,
      'productcount': productCount,
      'sortby': 'price',
      'startafterval': double.parse(startAfterVal),
      'productid': lastProductId,
    });

    if (response.data['status'] == 'FAIL') return [];

    return (response.data['products'] as List<dynamic>).map((json) {
      return ProductModel.fromJson(json);
    }).toList();
  }

  Future<List<ProductModel>> getFirstProducts(String listType,
      [String? userid]) async {
    final response = await _apiService.post(
      url: 'products/$listType/searchfirst',
      body: {
        'psk': psk,
        'userid': userid,
        'productcount': productCount,
        'sortby': 'price',
        'sortdirection': listType == 'reco' ? 'ascending' : 'descending',
      },
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

  Future<List<ProductModel>> searchProducts(
    List<String> keyword, {
    String? lastProductId,
    String? startAfterVal,
  }) async {
    var _body = {
      'psk': psk,
      'keywords': keyword,
      'sortby': 'price',
      'sortdirection': 'ascending',
      'productcount': productCount,
    };
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
    required int rating,
  }) async {
    final response = await _apiService.post(
      url: 'products/update/${productRequest.productid}',
      body: {
        'psk': psk,
        ...productRequest.toJson(updating: true),
        // 'productid': productRequest.productid,
        // 'userid': productRequest.userid,
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
      url: 'products/update/${productRequest.productid}',
      body: {
        'psk': psk,
        'productid': productRequest.productid,
        'userid': userId,
        'like': like,
      },
    );
    print(response.data['status']);

    return response.data['status'] == 'SUCCESS';
  }
}
