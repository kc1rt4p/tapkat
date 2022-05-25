import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/localization.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/product_type.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_select_categories_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:tapkat/utilities/application.dart' as application;

class ProductAddScreen extends StatefulWidget {
  const ProductAddScreen({Key? key}) : super(key: key);

  @override
  _ProductAddScreenState createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  final _productBloc = ProductBloc();
  late AuthBloc _authBloc;

  List<SelectedMedia> _selectedMedia = [];

  final _nameTextController = TextEditingController();
  final _priceTextController = TextEditingController();
  final _offerTypeTextController = TextEditingController();
  final _descTextController = TextEditingController();
  final _locationTextController = TextEditingController();

  bool showImageError = false;
  String? _selectedOfferType;
  PlaceDetails? _selectedLocation;

  List<LocalizationModel> _locList = [];
  LocalizationModel? _selectedLocalization;

  final _formKey = GlobalKey<FormState>();

  User? _user;
  int _currentCarouselIndex = 0;
  final _carouselController = CarouselController();
  geoCoding.Placemark? _currentUserLoc;
  geoLocator.Position? _currentUserPosition;

  List<ProductTypeModel> _productTypes = [];
  List<ProductCategoryModel> _productCategories = [];
  bool isFree = false;

  @override
  void initState() {
    application.currentScreen = 'Product Add Screen';
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(GetCurrentuser());
    _loadUserLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        barrierEnabled: false,
        child: MultiBlocListener(
          listeners: [
            BlocListener(
              bloc: _authBloc,
              listener: (context, state) {
                if (state is AuthLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is GetCurrentUsersuccess) {
                  setState(() {
                    _user = state.user;
                  });

                  _productBloc.add(InitializeAddUpdateProduct());
                }
              },
            ),
            BlocListener(
              bloc: _productBloc,
              listener: (context, state) async {
                if (state is ProductLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is InitializeAddUpdateProductSuccess) {
                  setState(() {
                    _productCategories = state.categories;
                    _productTypes = state.types;
                    _selectedOfferType = _productTypes[0].code;
                    _locList = state.locList;

                    if (application.currentUserModel!.currency != null &&
                        application.currentUserModel!.currency!.isNotEmpty)
                      _selectedLocalization = _locList.firstWhere((loc) =>
                          loc.currency ==
                          application.currentUserModel!.currency);
                    else
                      _selectedLocalization = _locList.firstWhere((loc) =>
                          loc.country_code == application.currentCountry);
                  });
                }

                if (state is SaveProductSuccess) {
                  await DialogMessage.show(context,
                      message: 'An offer has been added');

                  Navigator.pop(context);
                }

                if (state is ProductError) {
                  print('====ERROR PRODUCT BLOC: ${state.message}');
                }
              },
            ),
          ],
          child: Container(
            color: Color(0xFFEBFBFF),
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Add to Your Store',
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 10.0,
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a product, event or service you want to offer',
                              style: Style.bodyText2,
                            ),
                            SizedBox(height: 10.0),
                            _buildPhoto(),
                            Visibility(
                              visible: showImageError,
                              child: Text(
                                'Please select image(s) of your offer',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.red.shade400,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            CustomTextFormField(
                              label: 'Name',
                              hintText: 'Enter your offer\'s name',
                              controller: _nameTextController,
                              color: kBackgroundColor,
                              validator: (val) => val != null && val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: CustomTextFormField(
                                      label: 'Price',
                                      hintText: 'Enter the price you want',
                                      controller: _priceTextController,
                                      color: kBackgroundColor,
                                      validator: (val) =>
                                          val != null && val.isEmpty
                                              ? 'Required'
                                              : null,
                                      keyboardType: TextInputType.number,
                                      isReadOnly: isFree,
                                      removeMargin: true,
                                      prefix: InkWell(
                                        onTap: _onCurrencySelect,
                                        child: Container(
                                          margin: EdgeInsets.only(right: 8.0),
                                          child: Text(
                                              _selectedLocalization != null
                                                  ? _selectedLocalization!
                                                      .currency!
                                                  : 'PHP',
                                              style: TextStyle(
                                                color: Colors.white,
                                              )),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.0),
                                  Column(
                                    children: [
                                      Text('FREE',
                                          style: TextStyle(
                                            fontSize:
                                                SizeConfig.textScaleFactor * 13,
                                            color: kBackgroundColor,
                                            fontWeight: FontWeight.w600,
                                          )),
                                      SizedBox(height: 5.0),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isFree = !isFree;
                                          });

                                          _priceTextController.text =
                                              isFree ? '0' : '';
                                        },
                                        child: Icon(
                                          isFree
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          color: kBackgroundColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            CustomTextFormField(
                              label: 'Description',
                              hintText: 'Enter a description',
                              controller: _descTextController,
                              color: kBackgroundColor,
                              maxLines: 3,
                              validator: (val) => val != null && val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 16.0),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: kBackgroundColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Offer Type',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 12.0),
                                  _productTypes.length > 0
                                      ? FittedBox(
                                          child: ToggleSwitch(
                                            activeBgColor: [
                                              kBackgroundColor,
                                            ],
                                            initialLabelIndex: 0,
                                            minWidth: double.infinity,
                                            minHeight: 25.0,
                                            borderColor: [Color(0xFFEBFBFF)],
                                            totalSwitches: _productTypes.length,
                                            labels: _productTypes
                                                .map((pt) => pt.name!)
                                                .toList(),
                                            onToggle: (index) {
                                              _selectedOfferType =
                                                  _productTypes[index!].code;
                                            },
                                            customTextStyles: [
                                              TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    SizeConfig.textScaleFactor *
                                                        15,
                                                color: Colors.white,
                                              ),
                                              TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    SizeConfig.textScaleFactor *
                                                        15,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
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
                              validator: (val) => val != null && val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            CustomButton(
                              label: 'Next',
                              onTap: _onSaveTapped,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onCurrencySelect() async {
    final localization = await showDialog<LocalizationModel?>(
        context: context,
        barrierDismissible: false,
        builder: (dContext) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Default Country',
                        style: Style.subtitle2.copyWith(
                            color: kBackgroundColor,
                            fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Icon(
                          FontAwesomeIcons.times,
                          color: kBackgroundColor,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    shrinkWrap: true,
                    // mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0),
                      ..._locList.map(
                        (item) => ListTile(
                          title: Text(item.currency ?? ''),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(dContext, item),
                          selectedColor: Color(0xFFBB3F03),
                          selected: _selectedLocalization == item,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });

    if (localization != null) {
      setState(() {
        _selectedLocalization = localization;
      });
    }
  }

  _loadUserLocation() async {
    if (await Permission.location.isDenied) return;
    if (!(await geoLocator.GeolocatorPlatform.instance
        .isLocationServiceEnabled())) return;
    try {
      List<geoCoding.Placemark> placemarks =
          await geoCoding.placemarkFromCoordinates(
              application.currentUserLocation!.latitude!.toDouble(),
              application.currentUserLocation!.longitude!.toDouble());
      if (placemarks.isNotEmpty) {
        placemarks.forEach((placemark) => print(placemark.toJson()));
        setState(() {
          _currentUserLoc = placemarks.first;
          _selectedLocation = PlaceDetails(
            placeId: '',
            name: _currentUserLoc!.name ?? '',
            geometry: Geometry(
              location: Location(
                lat: application.currentUserLocation!.latitude!.toDouble(),
                lng: application.currentUserLocation!.longitude!.toDouble(),
              ),
            ),
            addressComponents: [
              AddressComponent(
                longName: _currentUserLoc!.street ?? '',
                types: [],
                shortName: '',
              ),
              AddressComponent(
                longName: _currentUserLoc!.locality ?? '',
                types: [],
                shortName: '',
              ),
              AddressComponent(
                longName: _currentUserLoc!.subAdministrativeArea ?? '',
                types: [],
                shortName: '',
              ),
              AddressComponent(
                longName: _currentUserLoc!.country ?? '',
                types: [],
                shortName: '',
              ),
            ],
          );
          _locationTextController.text =
              '${_currentUserLoc!.street ?? ''}, ${_currentUserLoc!.locality ?? ''}, ${_currentUserLoc!.subAdministrativeArea ?? ''}, ${_currentUserLoc!.country ?? ''}';
        });
      }
    } catch (e) {}
  }

  _onSaveTapped() {
    if (_selectedMedia.length < 1) {
      setState(() {
        showImageError = true;
      });
    }
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation!.addressComponents.isNotEmpty) {
      var newProduct = ProductRequestModel(
        userid: _user!.uid,
        productname: _nameTextController.text.trim(),
        productdesc: _descTextController.text.trim(),
        free: isFree,
        price: double.parse(_priceTextController.text.trim()),
        type: _selectedOfferType!,
        location: LocationModel(
          longitude: _selectedLocation!.geometry!.location.lng,
          latitude: _selectedLocation!.geometry!.location.lat,
        ),
        address: _selectedLocation!.addressComponents[0] != null
            ? _selectedLocation!.addressComponents[0]!.longName
            : null,
        city: _selectedLocation!.addressComponents[1] != null
            ? _selectedLocation!.addressComponents[1]!.longName
            : null,
        country: _selectedLocation!.addressComponents.last != null
            ? _selectedLocation!.addressComponents.last!.longName
            : null,
        media_type: 'image',
      );

      if (_selectedLocalization != null) {
        newProduct.currency = _selectedLocalization!.currency;
      }

      if (_selectedLocation != null) {
        newProduct.address = _selectedLocation!.addressComponents[0] != null
            ? _selectedLocation!.addressComponents[0]!.longName
            : null;
        newProduct.city = _selectedLocation!.addressComponents[1] != null
            ? _selectedLocation!.addressComponents[1]!.longName
            : null;
        newProduct.country = _selectedLocation!.addressComponents.last != null
            ? _selectedLocation!.addressComponents.last!.longName
            : null;
        newProduct.location = LocationModel(
          longitude: _selectedLocation!.geometry!.location.lng,
          latitude: _selectedLocation!.geometry!.location.lat,
        );
      } else {
        if (_currentUserLoc != null && _currentUserPosition != null) {
          newProduct.address = _currentUserLoc!.street ?? '';
          newProduct.city = _currentUserLoc!.locality ?? '';
          newProduct.country = _currentUserLoc!.country ?? '';
          newProduct.location = LocationModel(
            longitude: _currentUserPosition!.longitude,
            latitude: _currentUserPosition!.latitude,
          );
        }
      }

      print('product request: ${newProduct.toJson()}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectProductCategoryScreen(
            productRequest: newProduct,
            media: _selectedMedia,
            categories: _productCategories,
          ),
        ),
      );
    }
  }

  _onPhotoTapped() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );

    if (selectedMedia != null &&
        validateFileFormat(selectedMedia.storagePath, context)) {
      setState(() {
        _selectedMedia.add(selectedMedia);
        showImageError = false;
      });
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

  Stack _buildPhoto() {
    return Stack(
      children: [
        _selectedMedia.length > 0
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CarouselSlider(
                      carouselController: _carouselController,
                      options: CarouselOptions(
                          height: 160.0,
                          enableInfiniteScroll: false,
                          aspectRatio: 1,
                          viewportFraction: 1,
                          onPageChanged: (index, _) {
                            setState(() {
                              _currentCarouselIndex = index;
                            });
                          }),
                      items: _selectedMedia.map((media) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Colors.white,
                                image: DecorationImage(
                                  image: FileImage(File(media.rawPath!)),
                                  scale: 1.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              height: 160.0,
                              width: double.infinity,
                            ),
                            Positioned(
                              top: 5,
                              right: 10,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedMedia.remove(media);
                                  });
                                  Future.delayed(Duration(milliseconds: 300),
                                      () => setState(() {}));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(50.0),
                                    // border: Border.all(color: Colors.black45),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(0, 0),
                                        blurRadius: 3.0,
                                      ),
                                    ],
                                  ),
                                  height: 30.0,
                                  width: 30.0,
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 20.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    Positioned(
                      bottom: 8,
                      child: Container(
                        width: SizeConfig.screenWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _selectedMedia.asMap().keys.map((key) {
                            return Container(
                              margin: _selectedMedia.length > 1
                                  ? key < 5
                                      ? EdgeInsets.only(right: 8.0)
                                      : null
                                  : null,
                              height: 8.0,
                              width: 8.0,
                              decoration: BoxDecoration(
                                color: _currentCarouselIndex == key
                                    ? Colors.white
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.grey,
                  image: DecorationImage(
                    image: AssetImage('assets/images/image_placeholder.jpg'),
                    scale: 1.0,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Text(''),
                height: 160.0,
                width: double.infinity,
              ),
        Visibility(
          visible: _selectedMedia.length < 5,
          child: Positioned(
            bottom: 5,
            right: 10,
            child: InkWell(
              onTap: _onPhotoTapped,
              child: Container(
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(50.0),
                  // border: Border.all(color: Colors.black45),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(0, 0),
                      blurRadius: 3.0,
                    ),
                  ],
                ),
                height: 30.0,
                width: 30.0,
                child: Icon(
                  _selectedMedia.length > 0
                      ? Icons.add_a_photo
                      : Icons.photo_camera,
                  color: Colors.white,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
