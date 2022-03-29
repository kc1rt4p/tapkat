import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/screens/root/barter/barter_transactions_screen.dart';
import 'package:tapkat/screens/root/home/home_screen.dart';
import 'package:tapkat/screens/root/profile/profile_screen.dart';
import 'package:tapkat/screens/root/wish_list/wish_list_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';

import 'bloc/root_bloc.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({Key? key}) : super(key: key);

  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final _screens = [
    HomeScreen(),
    WishListScreen(),
    BarterTransactionsScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;

  final _rootBloc = RootBloc();

  final _currentVerDate = DateTime(2022, 3, 28, 9);

  @override
  void initState() {
    Permission.location.request();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    SizeConfig().init(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlocProvider(
        create: (context) => _rootBloc,
        child: BlocListener(
          bloc: _rootBloc,
          listener: (context, state) {
            print('current root bloc state: $state');
            if (state is MoveToTab) {
              setState(() {
                _currentIndex = state.index;
              });
            }
          },
          child: Container(
            color: kBackgroundColor,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 3.0),
                  width: double.infinity,
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      'Version 1.0.${DateFormat('yyMMddHH').format(_currentVerDate)}_D',
                      style: TextStyle(fontSize: 10.0),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: kBackgroundColor,
                    child: _screens[_currentIndex],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: showFab && _currentIndex == 0 || _currentIndex == 3
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50.0),
              ),
              padding: EdgeInsets.all(8.0),
              child: FloatingActionButton(
                heroTag: 'addProductBtn',
                backgroundColor: Color(0xFFBB3F03),
                child: Icon(Icons.add, size: 30.0),
                onPressed: _onAddTapped,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  _onAddTapped() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductAddScreen(),
      ),
    );

    setState(() {
      _currentIndex = 1;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      print('current index: $_currentIndex');
      setState(() {
        _currentIndex = 3;
      });
    });
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: kToolbarHeight,
      color: Color(0xFFEBFBFF),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBottomNavItem(
              isActive: _currentIndex == 0,
              icon: Icons.home,
              index: 0,
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 1,
              icon: Icons.favorite,
              index: 1,
            ),
            Visibility(
              visible: _currentIndex == 0 || _currentIndex == 3,
              child: SizedBox(
                width: 50.0,
              ),
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 2,
              icon: Icons.repeat_outlined,
              index: 2,
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 3,
              icon: Icons.person,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildBottomNavItem({
    required IconData icon,
    required bool isActive,
    required int index,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          child: Icon(
            icon,
            color: isActive ? Color(0xFF94D2BD) : Colors.grey,
            size: isActive ? 30.0 : null,
          ),
        ),
      ),
    );
  }
}
