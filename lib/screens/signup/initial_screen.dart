import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/localization.dart';
import 'package:tapkat/screens/signup/photo_selection_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:tapkat/utilities/application.dart' as application;

class InitialSignUpScreen extends StatefulWidget {
  final String method;
  const InitialSignUpScreen({
    Key? key,
    required this.method,
  }) : super(key: key);

  @override
  _InitialSignUpScreenState createState() => _InitialSignUpScreenState();
}

class _InitialSignUpScreenState extends State<InitialSignUpScreen> {
  late AuthBloc _authBloc;
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _confirmPasswordTextController = TextEditingController();
  final _usernameTextController = TextEditingController();
  final _locationTextController = TextEditingController();
  final _mobileNumberTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PlaceDetails? _selectedLocation;

  geoCoding.Placemark? _currentUserLoc;
  geoLocator.Position? _currentUserPosition;

  List<LocalizationModel> _locList = [];

  @override
  void initState() {
    print('current user: ${application.currentUser}');
    application.currentScreen = 'Sign Up - Initial Screen';
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(InitiateSignUpScreen());
    super.initState();
    _loadUserLocation();
    if (application.currentUser != null) {
      _mobileNumberTextController.text =
          application.currentUser!.phoneNumber ?? '';
      _emailTextController.text = application.currentUser!.email ?? '';
      _usernameTextController.text = application.currentUser!.displayName ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        child: BlocListener(
          bloc: _authBloc,
          listener: (context, state) async {
            if (state is AuthLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is InitiatedSignUpScreen) {
              setState(() {
                _locList = state.locList;
              });
            }

            if (state is ShowSignUpPhoto) {
              final photo = await Navigator.push<SelectedMedia?>(
                context,
                MaterialPageRoute(
                  builder: (context) => SignUpPhotoSelectionScreen(),
                ),
              );

              if (photo != null) {
                _authBloc.add(SaveUserPhoto(context, photo));
              }
            }

            if (state is AuthError) {
              DialogMessage.show(context,
                  title: 'Error', message: state.message);
            }
          },
          child: Container(
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(
                      top: kToolbarHeight + SizeConfig.paddingTop),
                  width: SizeConfig.screenWidth,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(
                        'assets/images/loginscreen_bg.png',
                      ),
                    ),
                  ),
                  height: SizeConfig.screenHeight * .3,
                ),
                Positioned(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: FractionalOffset.topCenter,
                        end: FractionalOffset.bottomCenter,
                        colors: [
                          Colors.transparent,
                          kBackgroundColor,
                          kBackgroundColor,
                          kBackgroundColor,
                        ],
                        stops: [
                          0.1,
                          0.36,
                          1,
                          1,
                        ],
                      ),
                    ),
                    height: SizeConfig.screenHeight,
                    width: SizeConfig.screenWidth,
                  ),
                ),
                Container(
                  height: SizeConfig.screenHeight,
                  width: SizeConfig.screenWidth,
                  child: Column(
                    children: [
                      CustomAppBar(label: 'Sign Up'),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                              top: SizeConfig.screenHeight * .26),
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 30.0),
                          child: Center(
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Column(
                                      children: [
                                        Visibility(
                                          visible: (application.currentUser ==
                                                      null &&
                                                  widget.method != 'OTHER') ||
                                              (application.currentUser !=
                                                      null &&
                                                  widget.method == 'PHONE'),
                                          child: CustomTextFormField(
                                            hintText:
                                                'Enter your email address',
                                            label: 'Email Address',
                                            controller: _emailTextController,
                                            validator: (val) =>
                                                val != null && val.isEmpty
                                                    ? 'Required'
                                                    : null,
                                          ),
                                        ),
                                        Visibility(
                                          visible:
                                              application.currentUser == null,
                                          child: Column(
                                            children: [
                                              CustomTextFormField(
                                                hintText: 'Enter your password',
                                                label: 'Password',
                                                controller:
                                                    _passwordTextController,
                                                obscureText: true,
                                                validator: (val) =>
                                                    val != null && val.isEmpty
                                                        ? 'Required'
                                                        : null,
                                              ),
                                              CustomTextFormField(
                                                hintText:
                                                    'Confirm your password',
                                                label: 'Confirm Password',
                                                controller:
                                                    _confirmPasswordTextController,
                                                obscureText: true,
                                                validator: (val) {
                                                  if (val != null &&
                                                      val.isEmpty)
                                                    return 'Required';
                                                  if (val !=
                                                      _passwordTextController
                                                          .text
                                                          .trim())
                                                    return 'Passwords don\'t match!';

                                                  return null;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    CustomTextFormField(
                                      hintText:
                                          'Enter the display name you want',
                                      label: 'Display Name',
                                      controller: _usernameTextController,
                                      validator: (val) =>
                                          val != null && val.isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    Visibility(
                                      visible: (application.currentUser ==
                                                  null &&
                                              widget.method != 'OTHER') ||
                                          (application.currentUser != null &&
                                              widget.method != 'PHONE'),
                                      child: CustomTextFormField(
                                        hintText: 'Enter your mobile number',
                                        label: 'Mobile Number',
                                        controller: _mobileNumberTextController,
                                        keyboardType: TextInputType.phone,
                                        validator: (val) =>
                                            val != null && val.isEmpty
                                                ? 'Required'
                                                : null,
                                      ),
                                    ),
                                    CustomTextFormField(
                                      hintText: 'Tap to select Location',
                                      label: 'Location',
                                      controller: _locationTextController,
                                      validator: (val) =>
                                          val != null && val.isEmpty
                                              ? 'Required'
                                              : null,
                                      onTap: _handleSelectLocation,
                                      suffixIcon: GestureDetector(
                                        onTap: _handleSelectLocation,
                                        child: Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      isReadOnly: true,
                                    ),
                                    SizedBox(height: 16.0),
                                    CustomButton(
                                      bgColor: Colors.white,
                                      textColor: kBackgroundColor,
                                      label: 'Create Account',
                                      onTap: _onCreateAccount,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8.0),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                              ),
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pop(context);
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _onCreateAccount() {
    if (!_formKey.currentState!.validate()) return;
    LocalizationModel? localization;
    if (application.currentUserLocation != null && _currentUserLoc != null) {
      LocalizationModel? _loc;
      final countryCode = _currentUserLoc!.isoCountryCode;

      _locList.forEach((loc) {
        if (loc.country_code == countryCode) localization = loc;
      });
    }

    _authBloc.add(
      SignUp(
        method: widget.method,
        email: _emailTextController.text.trim(),
        password: _confirmPasswordTextController.text.trim(),
        username: _usernameTextController.text.trim(),
        location: _selectedLocation!,
        mobileNumber: _mobileNumberTextController.text.trim(),
        context: context,
        loc: localization,
      ),
    );
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

  Future<void> _handleSelectLocation() async {
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

  _loadUserLocation() async {
    if (application.currentUserLocation != null) {
      final position = application.currentUserLocation;
      List<geoCoding.Placemark> placemarks =
          await geoCoding.placemarkFromCoordinates(
              position!.latitude!.toDouble(), position.longitude!.toDouble());
      if (placemarks.isNotEmpty) {
        placemarks.forEach((placemark) => print(placemark.toJson()));
        setState(() {
          _currentUserLoc = placemarks.first;

          _selectedLocation = PlaceDetails(
            placeId: '',
            name: _currentUserLoc!.name ?? '',
            geometry: Geometry(
              location: Location(
                lat: position.latitude!.toDouble(),
                lng: position.longitude!.toDouble(),
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
}
