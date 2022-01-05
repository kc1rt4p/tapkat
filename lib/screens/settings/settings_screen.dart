import 'package:flutter/material.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
                    _buildListHeader('Account Settings'),
                    _buildListGroupItem('Change Password'),
                    _buildListGroupItem('Default Location'),
                    _buildListGroupItem('Default Currency'),
                    _buildListGroupItem('Delete Account'),
                    _buildListHeader('Notification Settings'),
                    _buildListHeader('Privacy & Security'),
                    _buildListHeader('Help & FAQ'),
                    _buildListHeader('Contact Us'),
                    _buildListHeader('Log Out'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildListGroupItem(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Text(
        label,
        style: Style.subtitle2.copyWith(color: kBackgroundColor),
      ),
    );
  }

  Container _buildListHeader(String label) {
    return Container(
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.only(bottom: 10.0),
      child: Text(
        label,
        style: Style.subtitle2
            .copyWith(color: kBackgroundColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
