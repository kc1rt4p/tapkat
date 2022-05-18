import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/localization.dart';
import 'package:tapkat/screens/root/profile/change_password_screen.dart';
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

  List<LocalizationModel> _localizations = [];
  LocalizationModel? _selectedLocalization;

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
                    Container(
                      width: double.infinity,
                      child: Column(
                        children: [
                          _buildListGroupItem(
                            label: 'Change Password',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePasswordScreen(),
                              ),
                            ),
                          ),
                          InkWell(
                              onTap: _onCountrySelect,
                              child: _buildListGroupItem(
                                  label: 'Default Country')),
                          _buildListGroupItem(label: 'Default Currency'),
                          _buildListGroupItem(label: 'Delete Account'),
                        ],
                      ),
                    ),
                    _buildListHeader(label: 'Notification Settings'),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(20, 8.0, 10, 8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Push Notifications',
                            style: Style.subtitle2.copyWith(
                                color: kBackgroundColor,
                                fontSize: SizeConfig.textScaleFactor * 13),
                          ),
                          Spacer(),
                          SizedBox(
                            height: 30.0,
                            width: 40.0,
                            child: FittedBox(
                              child: Switch(
                                value: pushNotif == 1,
                                onChanged: _onPushNotif,
                                activeColor: kBackgroundColor,
                              ),
                            ),
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

  _onCountrySelect() async {
    final sortBy = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Default Country',
                        style: Style.subtitle2.copyWith(
                            color: kBackgroundColor,
                            fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Icon(
                          FontAwesomeIcons.times,
                          color: kBackgroundColor,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    shrinkWrap: true,
                    // mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0),
                      ..._localizations.map(
                        (item) => ListTile(
                          title: Text(item.country ?? ''),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(context, item),
                          selectedColor: Color(0xFFBB3F03),
                          selected: _selectedLocalization == item,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
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
        _authBloc.add(SignOut(context));
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
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, 8.0, 20, 8.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: Text(
          label,
          style: Style.subtitle2.copyWith(
              color: kBackgroundColor,
              fontSize: SizeConfig.textScaleFactor * 13),
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
        child: Text(
          label,
          style: Style.subtitle2.copyWith(
              color: kBackgroundColor,
              fontWeight: FontWeight.bold,
              fontSize: SizeConfig.textScaleFactor * 14),
        ),
      ),
    );
  }
}
