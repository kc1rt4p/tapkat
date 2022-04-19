import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/screens/root/profile/interests_selection_screen.dart';
import 'package:tapkat/screens/root/profile/social_media_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:geolocator/geolocator.dart' as geoLocator;

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileBloc = ProfileBloc();

  final _displayNameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _phoneTextController = TextEditingController();
  final _locationTextController = TextEditingController();

  SelectedMedia? _selectedMedia;
  PlaceDetails? _selectedLocation;

  late UserModel _userModel;

  geoCoding.Placemark? _currentUserLoc;
  geoLocator.Position? _currentUserPosition;

  @override
  void initState() {
    _userModel = widget.user;

    _displayNameTextController.text = _userModel.display_name ?? '';
    _emailTextController.text = _userModel.email ?? '';
    _phoneTextController.text = _userModel.phone_number ?? '';
    _locationTextController.text = (_userModel.address != null &&
            _userModel.city != null &&
            _userModel.country != null)
        ? (_userModel.address ?? '') +
            ', ' +
            (_userModel.city ?? '') +
            ', ' +
            (_userModel.country ?? '')
        : '';

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        backgroundColor: Colors.white,
        indicatorColor: kBackgroundColor,
        child: MultiBlocListener(
          listeners: [
            BlocListener(
              bloc: _profileBloc,
              listener: (context, state) {
                if (state is ProfileLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is UpdateUserInfoSuccess) {
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
                  label: 'Edit Profile',
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 36.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildPhoto(),
                          SizedBox(height: 26.0),
                          CustomTextFormField(
                            label: 'Display Name',
                            hintText: 'Enter your display name',
                            controller: _displayNameTextController,
                            color: kBackgroundColor,
                          ),
                          CustomTextFormField(
                            label: 'Phone Number',
                            hintText: 'Enter your phone number',
                            controller: _phoneTextController,
                            color: kBackgroundColor,
                          ),
                          CustomTextFormField(
                            label: 'Email Address',
                            hintText: 'Enter your email address',
                            controller: _emailTextController,
                            color: kBackgroundColor,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CustomTextFormField(
                                  label: 'Location',
                                  isReadOnly: true,
                                  hintText: '',
                                  controller: _locationTextController,
                                  onTap: _onSelectLocation,
                                  color: kBackgroundColor,
                                  removeMargin: true,
                                ),
                              ),
                              SizedBox(width: 6.0),
                              InkWell(
                                onTap: _onUseMyLocation,
                                child: Container(
                                  width: 45.0,
                                  height: 45.0,
                                  decoration: BoxDecoration(
                                    color: kBackgroundColor,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: CustomButton(
                    label: 'Next',
                    onTap: _onNextTapped,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onNextTapped() async {
    var user = _userModel;
    user.display_name = _displayNameTextController.text.trim();
    user.phone_number = _phoneTextController.text.trim();
    user.email = _emailTextController.text.trim();

    if (_selectedLocation != null) {
      user.city = _selectedLocation!.addressComponents[1] != null
          ? _selectedLocation!.addressComponents[1]!.longName
          : null;
      user.address = _selectedLocation!.addressComponents[0] != null
          ? _selectedLocation!.addressComponents[0]!.longName
          : null;
      user.country = _selectedLocation!.addressComponents.last != null
          ? _selectedLocation!.addressComponents.last!.longName
          : null;
      user.location = LocationModel(
        longitude: _selectedLocation!.geometry!.location.lng,
        latitude: _selectedLocation!.geometry!.location.lat,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserSocialMediaAccountsScreen(
          user: user,
          op: 'edit',
        ),
      ),
    );

    // if (userWithSocialMedia != null)
    //   user = userWithSocialMedia;
    // else
    //   return;

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => InterestSelectionScreen(
    //       user: user,
    //     ),
    //   ),
    // );
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

  _onPhotoTapped() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );

    if (selectedMedia != null &&
        validateFileFormat(selectedMedia.storagePath, context)) {
      setState(() {
        _selectedMedia = selectedMedia;
      });

      _profileBloc.add(UpdateUserPhoto(_selectedMedia!));
    }
  }

  Stack _buildPhoto() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100.0),
            image: DecorationImage(
              image: _selectedMedia == null
                  ? (_userModel.photo_url != null && _userModel.photo_url != '')
                      ? CachedNetworkImageProvider(_userModel.photo_url!)
                      : AssetImage('assets/images/profile_placeholder.png')
                          as ImageProvider<Object>
                  : FileImage(
                      File(_selectedMedia!.rawPath!),
                    ),
              scale: 1.0,
              fit: BoxFit.cover,
            ),
          ),
          height: SizeConfig.screenWidth * 0.4,
          width: SizeConfig.screenWidth * 0.4,
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

  _onUseMyLocation() {
    DialogMessage.show(
      context,
      message: 'Do you want to use your current lcoation?',
      firstButtonClicked: _loadUserLocation,
      buttonText: 'Yes',
      secondButtonText: 'No',
    );
  }

  _loadUserLocation() async {
    if (await Permission.location.isDenied) return;
    if (!(await geoLocator.GeolocatorPlatform.instance
        .isLocationServiceEnabled())) return;
    final userLoc = await geoLocator.Geolocator.getCurrentPosition();
    List<geoCoding.Placemark> placemarks = await geoCoding
        .placemarkFromCoordinates(userLoc.latitude, userLoc.longitude);
    if (placemarks.isNotEmpty) {
      placemarks.forEach((placemark) => print(placemark.toJson()));
      setState(() {
        _currentUserLoc = placemarks.first;
        _currentUserPosition = userLoc;
        _selectedLocation = PlaceDetails(
          placeId: '',
          name: _currentUserLoc!.name ?? '',
          geometry: Geometry(
            location: Location(
              lat: _currentUserPosition!.latitude,
              lng: _currentUserPosition!.longitude,
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
  }
}
