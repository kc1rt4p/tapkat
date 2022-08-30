import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/screens/root/profile/interests_selection_screen.dart';
import 'package:tapkat/screens/root/profile/social_media_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:tapkat/utilities/application.dart' as application;

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
  final _productBloc = ProductBloc();

  final _displayNameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _phoneTextController = TextEditingController();
  final _locationTextController = TextEditingController();

  SelectedMedia? _selectedMedia;
  PlaceDetails? _selectedLocation;

  List<ProductCategoryModel> _categories = [];
  List<ProductCategoryModel> _selectedCategories = [];
  List<String> _wantedList = [];
  bool _textIsEmpty = false;
  final focusNode = FocusNode();
  final inputTextController = TextEditingController();

  late UserModel _userModel;

  geoCoding.Placemark? _currentUserLoc;
  geoLocator.Position? _currentUserPosition;

  String fbEmail = '';
  String googleEmail = '';

  @override
  void initState() {
    application.currentScreen = 'Edit Profile Screen';
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
    fbEmail = _userModel.fb_profile ?? '';
    googleEmail = _userModel.yt_profile ?? '';
    _wantedList = _userModel.items_wanted ?? [];

    super.initState();

    _productBloc.add(InitializeAddUpdateProduct());
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
              bloc: _productBloc,
              listener: (context, state) {
                if (state is ProductLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is InitializeAddUpdateProductSuccess) {
                  setState(() {
                    _categories = state.categories
                        .where((cat) =>
                            cat.type == 'PT1' &&
                            cat.name!.toLowerCase() != 'others')
                        .toList();
                  });

                  if (_userModel.interests != null &&
                      _userModel.interests!.isNotEmpty) {
                    _categories.forEach((cat) {
                      if (_userModel.interests!.contains(cat.code)) {
                        _selectedCategories.add(cat);
                      }
                    });
                  }
                }
              },
              child: Container(),
            ),
            BlocListener(
              bloc: _profileBloc,
              listener: (context, state) async {
                if (state is ProfileLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is LinkAccToSocialMediaSuccess) {
                  final platform = state.platform;
                  setState(() {
                    if (platform == 'facebook')
                      fbEmail = state.email;
                    else if (platform == 'google') googleEmail = state.email;
                  });
                }

                if (state is UpdateUserInfoSuccess) {
                  await DialogMessage.show(context,
                      message: 'Profile updated successfully!');
                  Navigator.pop(context);
                }
              },
            ),
          ],
          child: Container(
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Edit Profile',
                ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizeConfig.screenWidth > 500
                              ? SizedBox(height: SizeConfig.screenHeight * 0.1)
                              : SizedBox(),
                          _buildPhoto(),
                          SizedBox(height: 26.0),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 16.0),
                            color: Color(0xFFEBFBFF),
                            child: Column(
                              children: [
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
                                Container(
                                  constraints: BoxConstraints(maxWidth: 500.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Icon(
                                            Icons.my_location,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildSocialMediaForm(),
                          _buildInterestsForm(),
                          _buildItemsWantedForm(),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: 500.0),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 2.0,
                  ),
                  child: CustomButton(
                    bgColor: kBackgroundColor,
                    label: 'Update',
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

  Widget _buildItemsWantedForm() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What products or services are you looking for?',
          ),
          SizedBox(height: 16.0),
          TextFormField(
            focusNode: focusNode,
            controller: inputTextController,
            onChanged: (val) {
              setState(() {
                _textIsEmpty = val.isEmpty;
              });
            },
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kBackgroundColor),
              ),
              suffixIcon: GestureDetector(
                onTap: !_textIsEmpty
                    ? () {
                        setState(() {
                          _wantedList.add(inputTextController.text.trim());
                        });
                        inputTextController.clear();
                        focusNode.requestFocus();
                      }
                    : null,
                child: Icon(
                  FontAwesomeIcons.plus,
                  color: _textIsEmpty ? Colors.grey : kBackgroundColor,
                  size: 15.0,
                ),
              ),
            ),
            onFieldSubmitted: (val) {
              if (val.isNotEmpty) {
                setState(() {
                  _wantedList.add(val);
                });
                inputTextController.clear();
                focusNode.requestFocus();
              }
            },
          ),
          SizedBox(height: 25.0),
          Visibility(
            visible: _wantedList.isNotEmpty,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runSpacing: 8.0,
                    spacing: 8.0,
                    children: [
                      ..._wantedList
                          .map(
                            (val) => InkWell(
                              onTap: () {
                                setState(() {
                                  _wantedList.remove(val);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 5.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      val,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            SizeConfig.textScaleFactor * 15,
                                      ),
                                    ),
                                    SizedBox(width: 5.0),
                                    Icon(
                                      Icons.close,
                                      size: SizeConfig.textScaleFactor * 13,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _wantedList.clear();
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 5.0, 5.0, 0.0),
                      child: Text(
                        'Clear items',
                        style: TextStyle(
                          color: kBackgroundColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsForm() {
    return Container(
      width: double.infinity,
      color: Color(0xFFEBFBFF),
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          Text(
            'Select your interests, this will help us show you offers from other users that you might be interested',
          ),
          _categories.isNotEmpty
              ?
              // Wrap(
              //     spacing: 10.0,
              //     runSpacing: 10.0,
              //     children: _categories
              //         .where((cat) => cat.type == 'PT1')
              //         .map((cat) => Center(
              //               child: InkWell(
              //                 onTap: () {
              //                   setState(() {
              //                     // _selectedCategory = cat;
              //                     if (_selectedCategories.contains(cat))
              //                       _selectedCategories.remove(cat);
              //                     else
              //                       _selectedCategories.add(cat);
              //                   });
              //                 },
              //                 child: Container(
              //                   height: SizeConfig.screenHeight * .08,
              //                   width: SizeConfig.screenWidth * .25,
              //                   padding: EdgeInsets.all(3.0),
              //                   decoration: BoxDecoration(
              //                     borderRadius: BorderRadius.circular(10.0),
              //                     color: _selectedCategories.contains(cat)
              //                         ? kBackgroundColor
              //                         : Color(0xFFEBFBFF),
              //                     border: _selectedCategories.contains(cat)
              //                         ? null
              //                         : Border.all(color: kBackgroundColor),
              //                   ),
              //                   child: Center(
              //                     child: Text(
              //                       cat.name ?? '',
              //                       style: TextStyle(
              //                         color: _selectedCategories.contains(cat)
              //                             ? Colors.white
              //                             : kBackgroundColor,
              //                         fontSize: SizeConfig.screenWidth > 500
              //                             ? SizeConfig.textScaleFactor * 16
              //                             : SizeConfig.textScaleFactor * 11,
              //                         fontWeight: FontWeight.w800,
              //                       ),
              //                       textAlign: TextAlign.center,
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //             ))
              //         .toList(),
              //   )

              GridView.count(
                  padding: EdgeInsets.only(top: 20.0),
                  shrinkWrap: true,
                  childAspectRatio: 3 / 1.5,
                  crossAxisCount: 3,
                  mainAxisSpacing: 10.0,
                  physics: NeverScrollableScrollPhysics(),
                  children: _categories
                      .where((cat) => cat.type == 'PT1')
                      .map((cat) => Center(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  // _selectedCategory = cat;
                                  if (_selectedCategories.contains(cat))
                                    _selectedCategories.remove(cat);
                                  else
                                    _selectedCategories.add(cat);
                                });
                              },
                              child: Container(
                                height: SizeConfig.screenHeight * .08,
                                width: SizeConfig.screenWidth * .25,
                                padding: EdgeInsets.all(3.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: _selectedCategories.contains(cat)
                                      ? kBackgroundColor
                                      : Color(0xFFEBFBFF),
                                  border: _selectedCategories.contains(cat)
                                      ? null
                                      : Border.all(color: kBackgroundColor),
                                ),
                                child: Center(
                                  child: Text(
                                    cat.name ?? '',
                                    style: TextStyle(
                                      color: _selectedCategories.contains(cat)
                                          ? Colors.white
                                          : kBackgroundColor,
                                      fontSize: SizeConfig.screenWidth > 500
                                          ? SizeConfig.textScaleFactor * 16
                                          : SizeConfig.textScaleFactor * 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                )
              : Container(),
        ],
      ),
    );
  }

  Widget _buildSocialMediaForm() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You may link your social media accounts',
          ),
          SizedBox(height: 16.0),
          _buildSocialMediaField(platform: 'Facebook', email: fbEmail),
          _buildSocialMediaField(platform: 'Google', email: googleEmail),
        ],
      ),
    );
  }

  Widget _buildSocialMediaField(
      {required String platform, required String email}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          email.isNotEmpty
              ? Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: kBackgroundColor,
                            fontFamily: 'Poppins',
                          ),
                          children: [
                            TextSpan(text: 'Linked to '),
                            TextSpan(
                              text: email,
                              style: TextStyle(
                                color: kBackgroundColor,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (platform.toLowerCase() == 'facebook') {
                            fbEmail = '';
                          } else if (platform.toLowerCase() == 'google') {
                            googleEmail = '';
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(3.0),
                        child: Icon(
                          FontAwesomeIcons.trash,
                          color: Colors.red.shade400,
                          size: 15.0,
                        ),
                      ),
                    ),
                  ],
                )
              : TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () =>
                      _profileBloc.add(LinkAccToSocialMedia('facebook')),
                  child: Text(
                    'Link your $platform account',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: kBackgroundColor,
                    ),
                  ),
                ),
        ],
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

    user.yt_profile = googleEmail;
    user.fb_profile = fbEmail;
    user.interests = _selectedCategories.map((scat) => scat.code!).toList();
    user.items_wanted = _wantedList;
    print('~~~ ${user.toJson()}');
    final _user = UpdateUserModel.fromUser(user);
    print('~~~ ${_user.toJson()}');
    _profileBloc.add(UpdateUserInfo(_user));

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => UserSocialMediaAccountsScreen(
    //       user: user,
    //       op: 'edit',
    //     ),
    //   ),
    // );

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

    if (selectedMedia != null) {
      setState(() {
        _selectedMedia = selectedMedia.first;
      });

      _profileBloc.add(UpdateUserPhoto(_selectedMedia!));
    }
  }

  Stack _buildPhoto() {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 16.0),
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
    if (!kIsWeb) {
      if (await Permission.location.isDenied) return;
    }
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
