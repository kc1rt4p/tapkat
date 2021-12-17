import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/screens/signup/initial_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthBloc _authBloc;
  final _usernameTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  bool _showPassword = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        child: BlocListener(
          bloc: _authBloc,
          listener: (context, state) {
            if (state is AuthLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
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
                    children: [
                      SizedBox(height: SizeConfig.screenHeight * .34),
                      Expanded(
                        child: Container(
                          width: SizeConfig.screenWidth,
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
                                    CustomTextFormField(
                                      hintText: 'Enter your username',
                                      label: 'Username',
                                      controller: _usernameTextController,
                                      validator: (val) =>
                                          val != null && val.isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    CustomTextFormField(
                                      hintText: 'Enter your password',
                                      label: 'Password',
                                      controller: _passwordTextController,
                                      obscureText: !_showPassword,
                                      suffixIcon: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                        child: FaIcon(
                                          _showPassword
                                              ? FontAwesomeIcons.solidEyeSlash
                                              : FontAwesomeIcons.solidEye,
                                          color: Colors.white,
                                        ),
                                      ),
                                      validator: (val) =>
                                          val != null && val.isEmpty
                                              ? 'Required'
                                              : null,
                                    ),
                                    CustomButton(
                                      onTap: _onLogInTapped,
                                      label: 'Log In',
                                    ),
                                    SizedBox(height: 20.0),
                                    CustomButton(
                                      onTap: () {},
                                      label: 'Sign in with Facebook',
                                      icon: SvgPicture.asset(
                                        'assets/icons/fb_icon.svg',
                                        height: 20.0,
                                      ),
                                      bgColor: Colors.white,
                                      textColor: Colors.black,
                                    ),
                                    CustomButton(
                                      onTap: () {},
                                      label: 'Sign in with Google',
                                      icon: SvgPicture.asset(
                                        'assets/icons/google_icon.svg',
                                        height: 20.0,
                                      ),
                                      bgColor: Colors.white,
                                      textColor: Colors.black,
                                    ),
                                    CustomButton(
                                      onTap: () {},
                                      label: 'Sign in with Apple',
                                      icon: SvgPicture.asset(
                                        'assets/icons/apple_icon.svg',
                                        height: 20.0,
                                      ),
                                      bgColor: Colors.white,
                                      textColor: Colors.black,
                                    ),
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
                                                                  InitialSignUpScreen(),
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

  _onLogInTapped() {
    print(_formKey.currentState!.validate());
    if (!_formKey.currentState!.validate()) return;

    _authBloc.add(SignInWithEmail(
      context: context,
      email: _usernameTextController.text.trim(),
      password: _passwordTextController.text.trim(),
    ));
  }
}
