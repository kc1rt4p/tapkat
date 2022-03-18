import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
      body: Container(
        child: Column(
          children: [
            CustomAppBar(
              label: 'Settings',
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildListHeader(label: 'Account Settings'),
                    _buildListGroupItem(label: 'Change Password'),
                    _buildListGroupItem(label: 'Default Location'),
                    _buildListGroupItem(label: 'Default Currency'),
                    _buildListGroupItem(label: 'Delete Account'),
                    _buildListHeader(label: 'Notification Settings'),
                    _buildListHeader(label: 'Privacy & Security'),
                    _buildListHeader(label: 'Help & FAQ'),
                    _buildListHeader(label: 'Contact Us'),
                    _buildListHeader(
                      label: 'Log Out',
                      onTap: _onSignOut,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onSignOut() {
    DialogMessage.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to log out?',
      buttonText: 'Yes',
      firstButtonClicked: () {
        Navigator.pop(context);
        _authBloc.add(SignOut());
      },
      secondButtonText: 'No',
      hideClose: true,
    );
  }

  InkWell _buildListGroupItem({
    required String label,
    Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
        margin: EdgeInsets.only(bottom: 10.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: Text(
          label,
          style: Style.subtitle2.copyWith(color: kBackgroundColor),
        ),
      ),
    );
  }

  InkWell _buildListHeader({
    required String label,
    Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.0),
        margin: EdgeInsets.only(bottom: 10.0),
        child: Text(
          label,
          style: Style.subtitle2
              .copyWith(color: kBackgroundColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
