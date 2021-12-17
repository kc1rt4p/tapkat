import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AuthBloc _authBloc;

  @override
  void initState() {
    _authBloc = BlocProvider.of(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: BlocListener(
        bloc: _authBloc,
        listener: (context, state) {
          // TODO: implement listener
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
              height: SizeConfig.screenHeight * .5,
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
                  stops: [0.1, 0.5, 1, 1],
                ),
              ),
              height: SizeConfig.screenHeight,
              width: SizeConfig.screenWidth,
            ),
            Positioned(
              top: SizeConfig.screenHeight * .45,
              child: Container(
                height: SizeConfig.screenHeight * .6,
                padding: EdgeInsets.symmetric(
                  horizontal: 50.0,
                ),
                width: SizeConfig.screenWidth,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'Discover Bargaining Near You',
                        style: Style.title1.copyWith(
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Looking for some bargains? TapKat allows you to explore the best deals around you with just few flicks and clicks.',
                        style: Style.bodyText1.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 35.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Container(
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.grey.shade400,
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Container(
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.grey.shade400,
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Container(
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.grey.shade400,
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Container(
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                        height: SizeConfig.screenHeight * .3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomButton(
                              label: 'Create an Account',
                              onTap: () {},
                            ),
                            CustomButton(
                              label: 'Continue as a Guest',
                              onTap: () => _authBloc.add(SignInAsGuest()),
                              bgColor: Color(0xFFBB3F03),
                            ),
                            Text('Already have an account?'),
                            SizedBox(height: 7.0),
                            CustomButton(
                              label: 'Log In',
                              onTap: () {},
                              bgColor: Color(0xFFBB3F03),
                              removeMargin: true,
                            ),
                          ],
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
    );
  }
}
