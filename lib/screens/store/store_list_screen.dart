import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/screens/store/component/store_list_item.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({Key? key}) : super(key: key);

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  final _storeBloc = StoreBloc();
  final _storePageController =
      PagingController<int, StoreModel>(firstPageKey: 0);
  StoreModel? lastStore;
  List<StoreModel> _list = [];
  int currentPage = 0;

  @override
  void initState() {
    _storeBloc.add(GetFirstTopStores());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener(
        bloc: _storeBloc,
        listener: (context, state) {
          if (state is GetFirstTopStoresSuccess) {
            if (state.list.isNotEmpty) {
              _list.addAll(state.list);

              lastStore = state.list.last;

              if (state.list.length == productCount) {
                _storePageController.appendPage(state.list, currentPage + 1);
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
                _storePageController.appendPage(state.list, currentPage + 1);
              } else {
                _storePageController.appendLastPage(state.list);
              }
            } else {
              _storePageController.appendLastPage([]);
            }
          }
        },
        child: Column(
          children: [
            CustomAppBar(
              label: 'Top Stores',
            ),
            CustomSearchBar(
              controller: TextEditingController(),
              hintText: 'Search store name',
              backgroundColor: kBackgroundColor,
              textColor: Colors.white,
            ),
            Expanded(
              child: PagedGridView<int, StoreModel>(
                pagingController: _storePageController,
                showNewPageProgressIndicatorAsGridChild: false,
                showNewPageErrorIndicatorAsGridChild: false,
                showNoMoreItemsIndicatorAsGridChild: false,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 16,
                  crossAxisCount: 2,
                ),
                builderDelegate: PagedChildBuilderDelegate<StoreModel>(
                  itemBuilder: (context, store, index) => StoreListItem(
                    store,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
