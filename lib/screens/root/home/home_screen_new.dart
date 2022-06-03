import 'package:flutter/material.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({Key? key}) : super(key: key);

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            height: kToolbarHeight,
          ),
        ],
      ),
    );
  }
}
