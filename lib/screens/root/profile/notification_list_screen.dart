import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/notification.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<NotificationModel> _list = [];
  final _profileBloc = ProfileBloc();
  final _pagingController =
      PagingController<int, NotificationModel>(firstPageKey: 1);
  NotificationModel? lastNotification;
  int currentPage = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _profileBloc.add(InitializeNotificationList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProgressHUD(
        child: Column(
          children: [
            CustomAppBar(
              label: 'Notifications',
            ),
            Expanded(
              child: BlocListener(
                bloc: _profileBloc,
                listener: (context, state) {
                  if (state is InitializeNotificationListSuccess) {
                    _pagingController.refresh();

                    if (state.list.isNotEmpty) {
                      lastNotification = state.list.last;
                      if (state.list.length == 8) {
                        _pagingController.appendPage(
                            state.list, currentPage + 1);
                      } else {
                        _pagingController.appendLastPage(state.list);
                      }
                    } else {
                      _pagingController.appendLastPage([]);
                    }
                    _pagingController.addPageRequestListener((pageKey) {
                      if (lastNotification != null) {
                        _profileBloc.add(
                            GetNextNotifications(lastNotification!.timestamp!));
                      }
                    });
                  }
                },
                child: Container(
                  child: PagedListView.separated(
                    pagingController: _pagingController,
                    separatorBuilder: (context, index) => Divider(
                        height: 2, thickness: 0.9, color: kBackgroundColor),
                    builderDelegate:
                        PagedChildBuilderDelegate<NotificationModel>(
                      itemBuilder: (context, notf, index) => ListTile(
                        title: Text(notf.title ?? ''),
                        subtitle: Text(notf.body ?? ''),
                        dense: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarterScreen(
                              barterRecord:
                                  BarterRecordModel(barterId: notf.barterid),
                              showChatFirst: true,
                            ),
                          ),
                        ),
                        style: ListTileStyle.list,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              timeago.format(
                                DateTime.parse(notf.timestamp!),
                              ),
                              style: TextStyle(
                                  fontSize: SizeConfig.textScaleFactor * 12),
                            ),
                            Visibility(
                              visible: !notf.read!,
                              child: Container(
                                margin: EdgeInsets.only(top: 8.0),
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kDangerColor,
                                ),
                              ),
                            ),
                          ],
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
