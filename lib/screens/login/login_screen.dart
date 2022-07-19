import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/screens/signup/initial_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:tapkat/utilities/application.dart' as application;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthBloc _authBloc;
  final _usernameTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _phoneTextController = TextEditingController();
  final _otpTextController = TextEditingController();
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();
  bool _signInWithPhone = false;
  bool _verifyingPhone = false;
  String? _verificationId;
  String? _phoneNumber;
  bool _showPhoneError = false;
  String _phoneErrorMsg = '';
  PhoneNumber _selectedPhoneCountry = PhoneNumber(isoCode: 'SG');

  late Timer _timer;
  int currentSeconds = 0;
  int timerMaxSeconds = 30;
  bool timerExpired = true;
  int? _forceResendingToken;

  String get timerText =>
      '${((timerMaxSeconds - currentSeconds) ~/ 60).toString().padLeft(2, '0')}:${((timerMaxSeconds - currentSeconds) % 60).toString().padLeft(2, '0')}';

  void startTimer() {
    setState(() {
      timerExpired = false;
    });
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(oneSec, (Timer timer) {
      if (this.mounted) {
        setState(() {
          currentSeconds = timer.tick;
          if (currentSeconds >= timerMaxSeconds) {
            timer.cancel();
            setState(() {
              timerExpired = true;
            });
          }
        });
      }
    });
  }

  @override
  void initState() {
    application.currentScreen = 'Login Screen';
    _authBloc = BlocProvider.of<AuthBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kBackgroundColor,
      body: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        barrierEnabled: false,
        child: BlocListener(
          bloc: _authBloc,
          listener: (context, state) async {
            print('-====---- CURRENT LOGIN AUTH STATE:::: $state');
            if (state is AuthLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is ContinueSignUp) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InitialSignUpScreen(
                          method: 'OTHER',
                        )),
              );
            }

            if (state is PhoneOtpSentSuccess) {
              setState(() {
                _verificationId = state.verificationId;
                _verifyingPhone = true;
                _forceResendingToken = state.forceResendingToken;
              });
              print('FORCE RESENDING TOKEN ::::: ${state.forceResendingToken}');
              startTimer();
            }

            if (state is PhoneVerifiedButNoRecord) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InitialSignUpScreen(
                          method: 'PHONE',
                        )),
              );
            }

            if (state is AuthError) {
              DialogMessage.show(context,
                  title: 'Error', message: state.message);
            }
          },
          child: Container(
            height: SizeConfig.screenHeight,
            decoration: BoxDecoration(
              color: kBackgroundColor,
            ),
            child: Stack(
              children: [
                Container(
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
                  height: SizeConfig.screenHeight * .45,
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
                        stops: [0.1, 0.37, 1, 1],
                      ),
                    ),
                    height: SizeConfig.screenHeight,
                    width: SizeConfig.screenWidth,
                  ),
                ),
                Container(
                  height: SizeConfig.screenHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: SizeConfig.screenHeight * .34),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 50.0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Login to Your Account',
                                      style: Style.title2.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 16.0),
                                    _signInWithPhone
                                        ? _verifyingPhone
                                            ? Column(
                                                children: [
                                                  Text(
                                                    'A one-time password was send to ${_selectedPhoneCountry.dialCode! + _phoneTextController.text}',
                                                    style: Style.bodyText2
                                                        .copyWith(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: 5.0),
                                                  CustomTextFormField(
                                                    hintText:
                                                        'Enter the code sent to your phone',
                                                    label: 'OTP code',
                                                    controller:
                                                        _otpTextController,
                                                    validator: (val) =>
                                                        val != null &&
                                                                val.isEmpty
                                                            ? 'Required'
                                                            : null,
                                                    keyboardType:
                                                        TextInputType.number,
                                                  ),
                                                ],
                                              )
                                            : Container(
                                                constraints: BoxConstraints(
                                                    maxWidth: 500.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Color(0xFFE2E2E2)
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.0),
                                                        border: Border.all(
                                                          color:
                                                              kBackgroundColor,
                                                        ),
                                                      ),
                                                      child:
                                                          InternationalPhoneNumberInput(
                                                        initialValue:
                                                            _selectedPhoneCountry,
                                                        spaceBetweenSelectorAndTextField:
                                                            0,
                                                        textFieldController:
                                                            _phoneTextController,
                                                        selectorConfig:
                                                            SelectorConfig(
                                                          trailingSpace: false,
                                                          selectorType:
                                                              PhoneInputSelectorType
                                                                  .DIALOG,
                                                          setSelectorButtonAsPrefixIcon:
                                                              true,
                                                          leadingPadding: 0,
                                                        ),
                                                        inputDecoration:
                                                            InputDecoration(
                                                          hintStyle: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.3),
                                                            fontSize: SizeConfig
                                                                    .textScaleFactor *
                                                                15,
                                                          ),
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                          hintText:
                                                              'Enter your phone number',
                                                          isDense: true,
                                                        ),
                                                        onInputChanged:
                                                            (phoneNumber) {
                                                          setState(() {
                                                            _phoneNumber =
                                                                phoneNumber
                                                                    .phoneNumber;
                                                            _selectedPhoneCountry =
                                                                phoneNumber;
                                                          });
                                                        },
                                                        textStyle: TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: 'Poppins',
                                                          fontSize: SizeConfig
                                                                  .textScaleFactor *
                                                              15,
                                                        ),
                                                        selectorTextStyle:
                                                            TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: 'Poppins',
                                                          fontSize: SizeConfig
                                                                  .textScaleFactor *
                                                              15,
                                                        ),
                                                        validator: (val) {
                                                          if (val != null) {
                                                            if (val.isEmpty) {
                                                              setState(() {
                                                                _showPhoneError =
                                                                    true;
                                                                _phoneErrorMsg =
                                                                    'Required';
                                                              });
                                                              return null;
                                                            } else {
                                                              setState(() {
                                                                _phoneErrorMsg =
                                                                    '';
                                                                _showPhoneError =
                                                                    false;
                                                              });
                                                              return null;
                                                            }
                                                          } else {
                                                            setState(() {
                                                              _phoneErrorMsg =
                                                                  '';
                                                              _showPhoneError =
                                                                  false;
                                                            });
                                                            return null;
                                                          }
                                                        },
                                                        countries: ['PH', 'SG'],
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible: _showPhoneError,
                                                      child: Text(
                                                        _phoneErrorMsg,
                                                        style: TextStyle(
                                                          fontSize: 12.0,
                                                          color: Colors
                                                              .red.shade400,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 16.0),
                                                  ],
                                                ),
                                              )
                                        : Column(
                                            children: [
                                              CustomTextFormField(
                                                hintText: 'Enter your username',
                                                label: 'Username',
                                                controller:
                                                    _usernameTextController,
                                                validator: (val) =>
                                                    val != null && val.isEmpty
                                                        ? 'Required'
                                                        : null,
                                              ),
                                              CustomTextFormField(
                                                hintText: 'Enter your password',
                                                label: 'Password',
                                                controller:
                                                    _passwordTextController,
                                                obscureText: !_showPassword,
                                                suffixIcon: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _showPassword =
                                                          !_showPassword;
                                                    });
                                                  },
                                                  child: FaIcon(
                                                    _showPassword
                                                        ? FontAwesomeIcons
                                                            .solidEyeSlash
                                                        : FontAwesomeIcons
                                                            .solidEye,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                validator: (val) =>
                                                    val != null && val.isEmpty
                                                        ? 'Required'
                                                        : null,
                                              ),
                                            ],
                                          ),
                                    Container(
                                      constraints:
                                          BoxConstraints(maxWidth: 500.0),
                                      child: Row(
                                        children: [
                                          _verifyingPhone
                                              ? Expanded(
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: CustomButton(
                                                          enabled: timerExpired,
                                                          onTap:
                                                              _onResendTapped,
                                                          label: timerExpired
                                                              ? 'Resend'
                                                              : 'Resend ($timerText)',
                                                          bgColor: Style
                                                              .secondaryColor,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10.0),
                                                    ],
                                                  ),
                                                )
                                              : Text(''),
                                          Expanded(
                                            child: CustomButton(
                                              bgColor: Colors.white,
                                              textColor: kBackgroundColor,
                                              onTap: _onLogInTapped,
                                              label: _verifyingPhone
                                                  ? 'Submit'
                                                  : 'Log In',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20.0),
                                    CustomButton(
                                      onTap: () {
                                        setState(() {
                                          _signInWithPhone = !_signInWithPhone;
                                        });
                                        if (!_signInWithPhone) {
                                          _verifyingPhone = false;
                                        }
                                      },
                                      label:
                                          'Sign in with ${_signInWithPhone ? 'Email' : 'Phone'}',
                                      icon: Icon(
                                          _signInWithPhone
                                              ? Icons.email
                                              : Icons.phone,
                                          size: 20.0),
                                      bgColor: Colors.white,
                                      textColor: Colors.black,
                                    ),
                                    CustomButton(
                                      onTap: () =>
                                          _authBloc.add(SignInFacebook()),
                                      label: 'Sign in with Facebook',
                                      icon: SvgPicture.asset(
                                        'assets/icons/fb_icon.svg',
                                        height: 20.0,
                                      ),
                                      bgColor: Colors.white,
                                      textColor: Colors.black,
                                    ),
                                    CustomButton(
                                      onTap: () =>
                                          _authBloc.add(SignInGoogle()),
                                      label: 'Sign in with Google',
                                      icon: SvgPicture.asset(
                                        'assets/icons/google_icon.svg',
                                        height: 20.0,
                                      ),
                                      bgColor: Colors.white,
                                      textColor: Colors.black,
                                    ),
                                    // Visibility(
                                    //   visible: Platform.isIOS,
                                    //   child: CustomButton(
                                    //     onTap: () =>
                                    //         _authBloc.add(SignInApple()),
                                    //     label: 'Sign in with Apple',
                                    //     icon: SvgPicture.asset(
                                    //       'assets/icons/apple_icon.svg',
                                    //       height: 20.0,
                                    //     ),
                                    //     bgColor: Colors.white,
                                    //     textColor: Colors.black,
                                    //     enabled: Platform.isIOS,
                                    //   ),
                                    // ),
                                    Container(
                                      margin: EdgeInsets.only(bottom: 10.0),
                                      width: SizeConfig.screenWidth,
                                      child: Center(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                            children: [
                                              TextSpan(
                                                  text:
                                                      'Don\'t have an account? '),
                                              TextSpan(
                                                text: 'Sign Up Here',
                                                style: TextStyle(
                                                  decoration:
                                                      TextDecoration.underline,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () =>
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  InitialSignUpScreen(
                                                                method: 'EMAIL',
                                                              ),
                                                            ),
                                                          ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
          ),
        ),
      ),
    );
  }

  _onResendTapped() {
    _authBloc.add(SignInWithMobileNumber(_phoneNumber!, _forceResendingToken));
  }

  _onLogInTapped() {
    if (!_formKey.currentState!.validate()) return;
    if (_showPhoneError) return;

    if (_signInWithPhone) {
      if (_verifyingPhone) {
        _authBloc.add(
            VerifyPhoneOtp(_verificationId!, _otpTextController.text.trim()));
      } else {
        _authBloc.add(SignInWithMobileNumber(_phoneNumber!, null));
      }
    } else {
      _authBloc.add(SignInWithEmail(
        context: context,
        email: _usernameTextController.text.trim(),
        password: _passwordTextController.text.trim(),
      ));
    }
  }
}
