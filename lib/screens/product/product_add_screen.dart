import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';

class ProductAddScreen extends StatefulWidget {
  const ProductAddScreen({Key? key}) : super(key: key);

  @override
  _ProductAddScreenState createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  final _productBloc = ProductBloc();
  late AuthBloc _authBloc;

  SelectedMedia? _selectedMedia;

  final _nameTextController = TextEditingController();
  final _titleTextController = TextEditingController();
  final _priceTextController = TextEditingController();
  final _offerTypeTextController = TextEditingController();
  final _descTextController = TextEditingController();
  final _locationTextController = TextEditingController();

  bool showImageError = false;
  String? _selectedOfferType;
  PlaceDetails? _selectedLocation;

  final _formKey = GlobalKey<FormState>();
  final iOSGoogleMapsApiKey = 'AIzaSyBCyNgeJDA8_nwdGrPf5ecuIsVFRXSF0mQ';
  final androidGoogleMapsApiKey = 'AIzaSyAH4fWM5IbEO0X-Txkm6HNsFAQ3KOfW20I';
  final webGoogleMapsApiKey = 'AIzaSyAzPjfTTLzdfp-56tarHguvLXgdw7QAGkg';

  User? _user;

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(GetCurrentuser());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
          indicatorColor: kBackgroundColor,
          backgroundColor: Colors.white,
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

                  if (state is SaveOfferSuccess) {
                    await DialogMessage.show(context,
                        message: 'A new offer has been added');

                    Navigator.pop(context);
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
                              SizedBox(height: 10.0),
                              CustomTextFormField(
                                label: 'Name',
                                hintText: 'Enter your offer\'s name',
                                controller: _nameTextController,
                                color: kBackgroundColor,
                                validator: (val) => val != null && val.isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                              CustomTextFormField(
                                label: 'Price',
                                hintText: 'Enter the price you want',
                                controller: _priceTextController,
                                color: kBackgroundColor,
                                validator: (val) => val != null && val.isEmpty
                                    ? 'Required'
                                    : null,
                                keyboardType: TextInputType.number,
                              ),
                              CustomTextFormField(
                                label: 'Offer Type',
                                hintText: 'Tap to select type',
                                controller: _offerTypeTextController,
                                isReadOnly: true,
                                color: kBackgroundColor,
                                suffixIcon: Icon(
                                  FontAwesomeIcons.chevronDown,
                                  color: Colors.white,
                                ),
                                onTap: () => _onSelectOfferType(context),
                                validator: (val) => val != null && val.isEmpty
                                    ? 'Required'
                                    : null,
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
                                label: 'Save',
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
          )),
    );
  }

  _onSaveTapped() {
    if (_selectedMedia == null) {
      setState(() {
        showImageError = true;
      });
    }
    if (!_formKey.currentState!.validate()) return;

    _productBloc.add(SaveOffer(
      userid: _user!.uid,
      productname: _nameTextController.text.trim(),
      productdesc: _descTextController.text.trim(),
      price: double.parse(_priceTextController.text.trim()),
      type: _selectedOfferType!,
      selectedMedia: _selectedMedia!,
    ));
  }

  _onPhotoTapped() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );

    if (selectedMedia != null &&
        validateFileFormat(selectedMedia.storagePath, context)) {
      setState(() {
        _selectedMedia = selectedMedia;
        showImageError = false;
      });
    }
  }

  _onSelectOfferType(BuildContext context) async {
    final type = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
              child: ListView(
                shrinkWrap: true,
                // mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Offer Type',
                        style: Style.subtitle2.copyWith(
                          color: kBackgroundColor,
                        ),
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
                  SizedBox(height: 8.0),
                  ListTile(
                    title: Text('Product'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(context, 'product'),
                    selectedColor: Color(0xFFBB3F03),
                    selected: _selectedOfferType == 'product',
                  ),
                  ListTile(
                    title: Text('Service'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(context, 'service'),
                    selectedColor: Color(0xFFBB3F03),
                    selected: _selectedOfferType == 'service',
                  ),
                  ListTile(
                    title: Text('Event'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(context, 'event'),
                    selectedColor: Color(0xFFBB3F03),
                    selected: _selectedOfferType == 'event',
                  ),
                ],
              ),
            ),
          );
        });

    if (type != null) {
      setState(() {
        _selectedOfferType = type;
      });

      _offerTypeTextController.text = type[0].toUpperCase() + type.substring(1);
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
            image: DecorationImage(
              image: _selectedMedia == null
                  ? AssetImage('assets/images/image_placeholder.jpg')
                      as ImageProvider<Object>
                  : FileImage(
                      File(_selectedMedia!.rawPath!),
                    ),
              scale: 1.0,
              fit: BoxFit.cover,
            ),
          ),
          height: 150.0,
          width: double.infinity,
        ),
        Positioned(
          bottom: 0,
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
                Icons.photo_camera,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
