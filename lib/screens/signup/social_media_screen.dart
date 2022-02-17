import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';

class SignUpSocialMediaAccounts extends StatefulWidget {
  const SignUpSocialMediaAccounts({Key? key}) : super(key: key);

  @override
  _SignUpSocialMediaAccountsState createState() =>
      _SignUpSocialMediaAccountsState();
}

class _SignUpSocialMediaAccountsState extends State<SignUpSocialMediaAccounts> {
  late AuthBloc _authBloc;

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        barrierEnabled: false,
        child: BlocListener(
          bloc: _authBloc,
          listener: (context, state) {
            if (state is AuthLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is AuthSignedIn) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          child: Stack(
            children: [
              Container(
                width: SizeConfig.screenWidth,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(
                      'assets/images/splashscreen_bg.png',
                    ),
                  ),
                ),
                height: SizeConfig.screenHeight * .3,
              ),
              Container(
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
                    stops: [0.1, 0.3, 1, 1],
                  ),
                ),
                height: SizeConfig.screenHeight,
                width: SizeConfig.screenWidth,
              ),
              Positioned(
                top: SizeConfig.screenHeight * .33,
                child: Container(
                  height: SizeConfig.screenHeight * .7,
                  padding: EdgeInsets.symmetric(
                    horizontal: 50.0,
                  ),
                  width: SizeConfig.screenWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          'You can also share your social media accounts',
                          textAlign: TextAlign.center,
                          style: Style.bodyText1.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        CustomTextFormField(
                          label: 'Facebook',
                          hintText: 'Enter your Facebook URL',
                          controller: TextEditingController(),
                        ),
                        CustomTextFormField(
                          label: 'Instagram',
                          hintText: 'Enter your Instagram URL',
                          controller: TextEditingController(),
                        ),
                        CustomTextFormField(
                          label: 'Tiktok',
                          hintText: 'Enter your Tiktok URL',
                          controller: TextEditingController(),
                        ),
                        CustomTextFormField(
                          label: 'WhatsApp',
                          hintText: 'Enter your WhatsApp no.',
                          controller: TextEditingController(),
                        ),
                        CustomTextFormField(
                          label: 'Viber',
                          hintText: 'Enter your Viber no.',
                          controller: TextEditingController(),
                        ),
                        SizedBox(height: 22.0),
                        CustomButton(
                          label: 'Save & Continue',
                          onTap: () {
                            print('save/continue');
                          },
                        ),
                        CustomButton(
                          label: 'Skip',
                          onTap: () {
                            print('skip');
                            BlocProvider.of<AuthBloc>(context)
                                .add(SkipSignUpSocialMedia());
                          },
                          bgColor: Color(0xFFBB3F03),
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
    );
  }
}
