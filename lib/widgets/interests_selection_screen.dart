import 'package:flutter/material.dart';
import 'package:tapkat/models/user.dart';

class InterestsSelectionScreen extends StatefulWidget {
  final bool updating;
  final UserModel user;
  const InterestsSelectionScreen({
    Key? key,
    this.updating = false,
    required this.user,
  }) : super(key: key);

  @override
  State<InterestsSelectionScreen> createState() =>
      _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
