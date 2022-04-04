import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/screens/login/login_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authBloc = AuthBloc();
  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _authBloc,
      listener: (context, state) {
        if (state is AuthLoading) {
        } else {}

        if (state is ResendEmailSuccess) {
          DialogMessage.show(
            context,
            message: 'The email verification link has been resent',
            title: 'Resend Email',
          );
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            CustomAppBar(
              label: 'Email Verification',
              onBackTapped: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginScreen())),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.checkDouble,
                      size: 100.0,
                      color: kBackgroundColor,
                    ),
                    SizedBox(height: 32),
                    Text(
                      'Verify your Email Address',
                      style: Style.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      'We sent an email to make sure you own it',
                      textAlign: TextAlign.center,
                      style: Style.fieldText,
                    ),
                    Text(
                      'Please check your inbox and follow the instructions',
                      textAlign: TextAlign.center,
                      style: Style.fieldText,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomButton(
                onTap: () => _authBloc.add(ResendEmail()),
                label: 'Resend email',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
