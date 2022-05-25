import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tapkat/models/address.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';

import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:tapkat/utilities/application.dart' as application;

class ProductMeetUpLocationsScreen extends StatefulWidget {
  final List<SelectedMedia>? media;
  final ProductRequestModel productRequest;
  final bool updating;
  const ProductMeetUpLocationsScreen({
    Key? key,
    required this.productRequest,
    required this.updating,
    this.media,
  }) : super(key: key);

  @override
  State<ProductMeetUpLocationsScreen> createState() =>
      _ProductMeetUpLocationsScreenState();
}

class _ProductMeetUpLocationsScreenState
    extends State<ProductMeetUpLocationsScreen> {
  final _locationTextController = TextEditingController();

  PlaceDetails? _selectedLocation;
  List<AddressModel> _list = [];
  final _productBloc = ProductBloc();
  late ProductRequestModel _productRequest;

  @override
  void initState() {
    // TODO: implement initState
    application.currentScreen = 'Product MeetUp Screen';
    _productRequest = widget.productRequest;
    _list = List.from(_productRequest.meet_location ?? []);
    if (!widget.updating) {
      _list.add(AddressModel(
        city: application.currentUserModel!.city,
        country: application.currentUserModel!.country,
        address: application.currentUserModel!.address,
        location: application.currentUserModel!.location,
      ));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      child: BlocListener(
        bloc: _productBloc,
        listener: (context, state) async {
          if (state is ProductLoading) {
            ProgressHUD.of(context)!.show();
          } else {
            ProgressHUD.of(context)!.dismiss();
          }

          if (state is SaveProductSuccess) {
            await DialogMessage.show(context,
                message: 'An offer has been added');

            // Navigator.of(context).popUntil((route) => route.isFirst);
            var count = 0;
            Navigator.popUntil(context, (route) {
              return count++ == 4;
            });
          }

          if (state is EditProductSuccess) {
            await DialogMessage.show(context,
                message: 'The product has been updated.');

            var count = 0;
            Navigator.popUntil(context, (route) {
              return count++ == 4;
            });
          }
        },
        child: Scaffold(
          body: Column(
            children: [
              CustomAppBar(
                label: widget.updating ? 'Edit Product' : 'Add to Your Store',
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You may add up to 3 meet up locations',
                          style: Style.subtitle2),
                      SizedBox(height: 10.0),
                      CustomTextFormField(
                        label: 'Location',
                        hintText: 'Tap to search location',
                        controller: _locationTextController,
                        isReadOnly: true,
                        color: kBackgroundColor,
                        suffixIcon: Icon(
                          Icons.location_on,
                          color: Colors.white,
                        ),
                        onTap: () => _onSelectLocation(),
                        validator: (val) =>
                            val != null && val.isEmpty ? 'Required' : null,
                      ),
                      Container(
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                enabled: _selectedLocation != null,
                                removeMargin: true,
                                bgColor: kBackgroundColor,
                                label: 'Add location',
                                onTap: _onAddLocation,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(),
                      Expanded(
                        child: _list.isNotEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: ListView(
                                  children: _list
                                      .map(
                                        (address) => Container(
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(address.address ??
                                                            ''),
                                                      ],
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                      onTap: () => setState(
                                                          () => _list
                                                              .remove(address)),
                                                      child: Icon(Icons.close,
                                                          size: 18.0)),
                                                ],
                                              ),
                                              Divider(),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              )
                            : Center(
                                child: Text('No locations added'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        bgColor: kBackgroundColor,
                        label: 'Submit',
                        onTap: _onSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    _productRequest.meet_location = _list;

    if (widget.updating)
      _productBloc.add(EditProduct(_productRequest));
    else
      _productBloc.add(SaveProduct(
          productRequest: _productRequest, media: widget.media ?? []));
  }

  void _onAddLocation() {
    final loc = AddressModel(
      city: _selectedLocation!.addressComponents[1]!.longName,
      country: _selectedLocation!.addressComponents.last!.longName,
      address: _selectedLocation!.formattedAddress,
      location: LocationModel(
        latitude: _selectedLocation!.geometry!.location.lat,
        longitude: _selectedLocation!.geometry!.location.lng,
      ),
    );

    setState(() {
      _list.add(loc);
      _selectedLocation = null;
      _locationTextController.clear();
    });
  }

  Future<Null> displayPrediction(Prediction? p) async {
    if (p != null) {
      // get detail (lat/lng)
      GoogleMapsPlaces _places = GoogleMapsPlaces(
        apiKey: googleMapsApiKey,
        apiHeaders: await GoogleApiHeaders().getHeaders(),
      );
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId!);
      setState(() {
        _selectedLocation = detail.result;
      });
      _locationTextController.text = _selectedLocation!.formattedAddress!;
    }
  }

  String get googleMapsApiKey {
    if (kIsWeb) {
      return webGoogleMapsApiKey;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return '';
      case TargetPlatform.iOS:
        return iOSGoogleMapsApiKey;
      case TargetPlatform.android:
        return androidGoogleMapsApiKey;
      default:
        return webGoogleMapsApiKey;
    }
  }

  Future<void> _onSelectLocation() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: googleMapsApiKey,
      onError: (response) => print('Error occured when getting places response:'
          '\n${response.errorMessage}'),
      mode: Mode.overlay,
      types: [],
      components: [],
      strictbounds: false,
    );

    if (p != null && p.placeId != null) displayPrediction(p);
  }
}
