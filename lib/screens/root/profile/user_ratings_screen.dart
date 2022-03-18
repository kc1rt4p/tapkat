import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';

class UserRatingsScreen extends StatefulWidget {
  final UserModel user;
  const UserRatingsScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<UserRatingsScreen> createState() => _UserRatingsScreenState();
}

class _UserRatingsScreenState extends State<UserRatingsScreen> {
  final _profileBloc = ProfileBloc();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProgressHUD(
        child: BlocListener(
          bloc: _profileBloc,
          listener: (context, state) {
            // TODO: implement listener
          },
          child: Column(
            children: [
              CustomAppBar(
                label: 'User Ratings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
