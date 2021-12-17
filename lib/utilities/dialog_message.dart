import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:tapkat/widgets/custom_button.dart';

class DialogMessage {
  BuildContext? mContext;
  factory DialogMessage() => _instance;
  static final DialogMessage _instance = DialogMessage._internal();
  DialogMessage._internal();

  static DialogMessage get instance => _instance;

  static bool get isShow => _instance.mContext != null;

  static Future<dynamic> show(
    BuildContext context, {
    String? title,
    required String message,
    String? buttonText,
    String? secondButtonText,
    Widget? customMessage,
    bool isBanner = false,
    VoidCallback? firstButtonClicked,
    VoidCallback? secondButtonClicked,
    VoidCallback? closeButtonClicked,
    bool dismissible = false,
    bool forceDialog = false,
    bool hideClose = false,
  }) {
    if (forceDialog) {
      DialogMessage.dismiss();
    }
    if (instance.mContext == null && instance.mContext != context) {
      instance.mContext = context;

      return showDialog(
          context: context,
          barrierDismissible: dismissible,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (context) {
            if (!isBanner) {
              return WillPopScope(
                onWillPop: () => Future.value(dismissible),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                  scrollable: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.only(right: 4.0, top: 4.0, bottom: 4.0),
                        child: Text(
                          title ?? "Message",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: !hideClose,
                        child: GestureDetector(
                          onTap: () async {
                            await DialogMessage.dismiss();
                            if (closeButtonClicked != null) {
                              closeButtonClicked();
                            }
                          },
                          child: Icon(
                            Icons.close,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      customMessage ??
                          Text(
                            message,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      SizedBox(
                        height: 24,
                      ),
                      CustomButton(
                          label: buttonText ?? "Ok",
                          onTap: () async {
                            await DialogMessage.dismiss();
                            if (firstButtonClicked != null) {
                              firstButtonClicked();
                            }
                          }),
                      SizedBox(
                        height: 5,
                      ),
                      secondButtonText != null || secondButtonClicked != null
                          ? GestureDetector(
                              onTap: () async {
                                await DialogMessage.dismiss();
                                if (secondButtonClicked != null) {
                                  secondButtonClicked();
                                }
                              },
                              child: Text(
                                secondButtonText ?? "No",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                            )
                          : Container()
                    ],
                  ),
                ),
              );
            }
            return WillPopScope(
              onWillPop: () => Future.value(false),
              child: AlertDialog(
                  contentPadding: EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  content: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    height: 85,
                    width: 90,
                    child: Stack(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              image: DecorationImage(
                                  image: AssetImage(
                                      "assets/images/maintenance.png"),
                                  fit: BoxFit.fitHeight)),
                        ),
                        Align(
                          // These values are based on trial & error method
                          alignment: Alignment(1.05, -1.05),
                          child: InkWell(
                            onTap: () {
                              SystemChannels.platform
                                  .invokeMethod('SystemNavigator.pop');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            );
          });
    } else {
      debugPrint("===Dialog Already Show===");
      return Future.value(false);
    }
  }

  static Future<void> dismiss() async {
    if (instance.mContext != null) {
      Navigator.pop(instance.mContext!);
      instance.mContext = null;
      return;
    }
    return;
  }
}
