import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/store_like.dart';
import 'package:tapkat/models/top_store.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/application.dart' as application;

class StoreRepository {
  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');
  final _apiService = ApiService();

  Stream<QuerySnapshot<Map<String, dynamic>>> streamStoreLike(
    String storeId,
    String likerId,
  ) {
    return barterRef
        .where('userid', isEqualTo: storeId)
        .where('likerid', isEqualTo: likerId)
        .snapshots();
  }

  Future<List<TopStoreModel>> getNextTopStores({
    int itemCount = 10,
    required String sortBy,
    double radius = 5000,
    required LocationModel loc,
    required num startAfterVal,
    required String userId,
  }) async {
    final body = {
      "searcherid": application.currentUser!.uid,
      "itemcount": itemCount,
      "sortby": sortBy,
      "sortdirection": sortBy == 'rating' ? "descending" : "ascending",
      "radius": radius,
      "location": loc.toJson(),
      'startafterval': startAfterVal,
      'userid': userId,
    };

    final response = await _apiService.post(
      url: 'users/topV2/searchset',
      body: body,
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['users'] as List<dynamic>)
        .map((data) => TopStoreModel.fromJson(data))
        .toList();
  }

  Future<List<TopStoreModel>> getFirstTopStores({
    int? itemCount = 10,
    required String sortBy,
    double radius = 5000,
    required LocationModel loc,
  }) async {
    final body = {
      "searcherid": application.currentUser!.uid,
      "itemcount": itemCount,
      "sortby": sortBy,
      "sortdirection": sortBy == 'rating' ? "descending" : "ascending",
      "radius": radius,
      "location": loc.toJson()
    };

    final response = await _apiService.post(
      url: 'users/topV2/searchfirst',
      body: body,
    );

    if (response.data['status'] != 'SUCCESS') return [];
    return (response.data['users'] as List<dynamic>)
        .map((data) => TopStoreModel.fromJson(data))
        .toList();
  }
}
