import 'dart:async';

import 'package:algolia/algolia.dart';
import 'package:equatable/equatable.dart';
import 'package:tapkat/widgets/lat_lng.dart';

export 'package:algolia/algolia.dart';

const kAlgoliaApplicationId = 'AOEG4XR8I3';
const kAlgoliaApiKey = 'bf9ef72604de45f2cc0ff2668bc78775';

class AlgoliaQueryParams extends Equatable {
  const AlgoliaQueryParams(
      {this.term, this.latLng, this.maxResults, this.searchRadiusMeters});
  final String? term;
  final LatLng? latLng;
  final int? maxResults;
  final double? searchRadiusMeters;

  @override
  List<Object?> get props => [term, latLng, maxResults, searchRadiusMeters];
}

class FFAlgoliaManager {
  FFAlgoliaManager._()
      : algolia = Algolia.init(
          applicationId: kAlgoliaApplicationId,
          apiKey: kAlgoliaApiKey,
        );
  final Algolia algolia;

  static FFAlgoliaManager? _instance;
  static FFAlgoliaManager get instance => _instance ??= FFAlgoliaManager._();

  // Cache that will ensure identical queries are not repeatedly made.
  static Map<AlgoliaQueryParams, List<AlgoliaObjectSnapshot>> _algoliaCache =
      {};

  Future<List<AlgoliaObjectSnapshot>?> algoliaQuery({
    required String index,
    String? term,
    int? maxResults,
    FutureOr<LatLng?> location,
    double? searchRadiusMeters,
  }) async {
    // User must specify search term or location.
    if ((term ?? '').isEmpty && location == null) {
      return [];
    }
    LatLng? loc;

    if (location != null) {
      loc = await location;
    }

    final params = AlgoliaQueryParams(
      term: term,
      latLng: loc,
      maxResults: maxResults,
      searchRadiusMeters: searchRadiusMeters,
    );
    if (_algoliaCache.containsKey(params)) {
      return _algoliaCache[params];
    }

    AlgoliaQuery query = algolia.index(index);
    if (term != null) {
      query = query.query(term);
    }
    if (maxResults != null) {
      query = query.setHitsPerPage(maxResults);
    }
    query = query.setAroundLatLng('${loc!.latitude},${loc.longitude}');
    query = query.setAroundRadius(searchRadiusMeters?.round() ?? 'all');

    final snapshot = await query.getObjects();

    return _algoliaCache[params] = snapshot.hits;
  }
}
