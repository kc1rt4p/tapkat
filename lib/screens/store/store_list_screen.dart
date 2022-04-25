import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/screens/store/component/store_list_item.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

import 'package:tapkat/utilities/application.dart' as application;

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({Key? key}) : super(key: key);

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  final _storeBloc = StoreBloc();
  final _authBloc = AuthBloc();
  final _storePageController =
      PagingController<int, StoreModel>(firstPageKey: 0);
  StoreModel? lastStore;
  List<StoreModel> _list = [];
  int currentPage = 0;

  UserModel? _userModel;

  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');

  @override
  void initState() {
    _storeBloc.add(GetFirstTopStores());
    _authBloc.add(GetCurrentuser());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener(
            bloc: _authBloc,
            listener: (context, state) {
              if (state is GetCurrentUsersuccess) {
                setState(() {
                  _userModel = state.userModel;
                });
              }
            },
          ),
          BlocListener(
            bloc: _storeBloc,
            listener: (context, state) {
              if (state is GetFirstTopStoresSuccess) {
                if (state.list.isNotEmpty) {
                  _list.addAll(state.list);

                  lastStore = state.list.last;

                  if (state.list.length == productCount) {
                    _storePageController.appendPage(
                        state.list, currentPage + 1);
                  } else {
                    _storePageController.appendLastPage(state.list);
                  }
                } else {
                  _storePageController.appendLastPage([]);
                }

                // _refreshController.refreshCompleted();

                _storePageController.addPageRequestListener((pageKey) {
                  if (lastStore != null) {
                    _storeBloc.add(
                      GetNextTopStores(
                        lastUserId: lastStore!.userid!,
                        lastUserRating: lastStore!.rating!,
                      ),
                    );
                  } else {
                    _storePageController.refresh();
                  }
                });
              }

              if (state is GetNextTopStoresSuccess) {
                if (state.list.isNotEmpty) {
                  lastStore = state.list.last;
                  if (state.list.length == productCount) {
                    _storePageController.appendPage(
                        state.list, currentPage + 1);
                  } else {
                    _storePageController.appendLastPage(state.list);
                  }
                } else {
                  _storePageController.appendLastPage([]);
                }
              }
            },
          ),
        ],
        child: Column(
          children: [
            CustomAppBar(
              label: 'Top Stores',
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20.0,
              ),
              child: CustomSearchBar(
                controller: TextEditingController(),
                hintText: 'Search store name',
                backgroundColor: kBackgroundColor,
                textColor: Colors.white,
              ),
            ),
            Expanded(
              child: PagedGridView<int, StoreModel>(
                pagingController: _storePageController,
                showNewPageProgressIndicatorAsGridChild: false,
                showNewPageErrorIndicatorAsGridChild: false,
                showNoMoreItemsIndicatorAsGridChild: false,
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 16,
                  crossAxisCount: 2,
                ),
                builderDelegate: PagedChildBuilderDelegate<StoreModel>(
                  itemBuilder: (context, store, index) {
                    return FittedBox(
                      child: StoreListItem(
                        StoreModel(
                          display_name: store.display_name,
                          userid: store.userid,
                          photo_url: store.photo_url,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreScreen(
                              userId: store.userid!,
                              userName: store.display_name!,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
