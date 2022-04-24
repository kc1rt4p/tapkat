import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _profileBloc = ProfileBloc();
  late AuthBloc _authBloc;
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmNewPassword = false;

  final cpTextController = TextEditingController();
  final npTextController = TextEditingController();
  final cnpTextController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _authBloc = BlocProvider.of<AuthBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      child: Scaffold(
          body: BlocListener(
        bloc: _profileBloc,
        listener: (context, state) {
          if (state is ProfileLoading) {
            ProgressHUD.of(context)!.show();
          } else {
            ProgressHUD.of(context)!.dismiss();
          }

          if (state is ProfileError) {
            DialogMessage.show(
              context,
              message: state.message,
              title: 'Error changing Passowrd',
            );
          }

          if (state is UpdatePasswordSuccess) {
            DialogMessage.show(
              context,
              message: 'Password has changed.\n\nPlease login again.',
              buttonText: 'OK',
              firstButtonClicked: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                _authBloc.add(SignOut(context));
              },
            );
          }
        },
        child: Column(
          children: [
            CustomAppBar(
              label: 'Change Password',
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 26.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        showValue: showCurrentPassword,
                        controller: cpTextController,
                        label: 'Current password',
                        onTap: () => setState(
                            () => showCurrentPassword = !showCurrentPassword),
                        validator: (val) {
                          if (val != null && val.isEmpty) return 'Required';

                          return null;
                        },
                      ),
                      _buildTextField(
                        showValue: showNewPassword,
                        controller: npTextController,
                        label: 'New password',
                        onTap: () =>
                            setState(() => showNewPassword = !showNewPassword),
                        validator: (val) {
                          if (val != null && val.isEmpty) return 'Required';

                          return null;
                        },
                      ),
                      _buildTextField(
                        showValue: showConfirmNewPassword,
                        controller: cnpTextController,
                        label: 'Confirm new password',
                        onTap: () => setState(() =>
                            showConfirmNewPassword = !showConfirmNewPassword),
                        validator: (val) {
                          if (val != null && val.isEmpty) return 'Required';

                          if (val != npTextController.text.trim())
                            return 'Does not match new password';

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomButton(
                label: 'Update password',
                onTap: _onUpdatePassword,
              ),
            ),
          ],
        ),
      )),
    );
  }

  void _onUpdatePassword() {
    if (!_formKey.currentState!.validate()) return;

    DialogMessage.show(
      context,
      title: 'Change password',
      message:
          'You are about to change your password.\n\nDo you want to continue?',
      firstButtonClicked: () => _profileBloc.add(UpdatePassword(
          cpTextController.text.trim(), cnpTextController.text.trim())),
      buttonText: 'Yes',
      secondButtonText: 'No',
    );
  }

  Container _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool showValue,
    required Function() onTap,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.symmetric(
        horizontal: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Stack(
            alignment: Alignment.center,
            children: [
              TextFormField(
                controller: controller,
                obscureText: !showValue,
                keyboardType: TextInputType.visiblePassword,
                validator: validator,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(3.0, 5.0, 30.0, 3.0),
                  isDense: true,
                  border: UnderlineInputBorder(),
                  // suffixIconColor: kBackgroundColor,
                  // suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  // suffixStyle: TextStyle(color: kBackgroundColor),
                  // suffixIcon:
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: kBackgroundColor),
                  ),
                ),
              ),
              Positioned(
                top: 5.0,
                right: 3.0,
                child: GestureDetector(
                  child: Icon(
                    showValue ? Icons.visibility_off : Icons.visibility,
                    size: 15,
                  ),
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
