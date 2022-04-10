import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:notification_permissions/notification_permissions.dart'
    as notif;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AuthBloc _authBloc;

  int pushNotif = 0;

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    super.initState();
    initNotification();
  }

  initNotification() async {
    final permission =
        await notif.NotificationPermissions.getNotificationPermissionStatus();
    print(permission.toString());
    setState(() {
      pushNotif = permission == notif.PermissionStatus.denied
          ? 0
          : application.currentUserModel!.pushalert == 'Y'
              ? 1
              : 0;
    });
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
                    Container(
                      padding: EdgeInsets.fromLTRB(30, 10, 10, 10),
                      margin: EdgeInsets.only(bottom: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Push Notifications',
                              style: Style.subtitle2
                                  .copyWith(color: kBackgroundColor),
                            ),
                          ),
                          Switch(
                            value: pushNotif == 1,
                            onChanged: _onPushNotif,
                            activeColor: kBackgroundColor,
                          ),
                          // ToggleSwitch(
                          //   initialLabelIndex: pushNotif,
                          //   minWidth: 50,
                          //   minHeight: 20.0,
                          //   totalSwitches: 2,
                          //   activeBgColor: [kBackgroundColor],
                          //   inactiveFgColor: kBackgroundColor,
                          //   cornerRadius: 5.0,
                          //   labels: [
                          //     'Off',
                          //     'On',
                          //   ],
                          //   changeOnTap: false,
                          //   onToggle: _onPushNotif,
                          // ),
                        ],
                      ),
                    ),
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

  _onPushNotif(bool enable) async {
    DialogMessage.show(
      context,
      title: 'Push Notification',
      message:
          'Are you sure you want to turn ${enable ? 'on' : 'off'} notifications?',
      buttonText: 'Yes',
      firstButtonClicked: () async {
        setState(() {
          pushNotif = enable ? 1 : 0;
        });

        final settings = await FirebaseMessaging.instance.requestPermission();
        final permissionStatus = await notif.NotificationPermissions
            .requestNotificationPermissions();

        if (settings.authorizationStatus != AuthorizationStatus.authorized ||
            permissionStatus == notif.PermissionStatus.denied) return;

        _authBloc.add(UpdatePushAlert(pushNotif == 1));
      },
      secondButtonText: 'No',
      hideClose: true,
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
