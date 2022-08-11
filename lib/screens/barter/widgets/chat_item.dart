import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:photo_view/photo_view.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/helper.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:timeago/timeago.dart' as timeago;

Container buildChatItem(BuildContext context, ChatMessageModel msg,
    User? currentUser, String recipientName) {
  return Container(
    margin: EdgeInsets.only(top: 8.0),
    child: Column(
      crossAxisAlignment: msg.userId != currentUser!.uid
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: msg.userId != currentUser.uid
                ? kBackgroundColor
                : Color(0xFFBB3F03),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
              bottomLeft: msg.userId == currentUser.uid
                  ? Radius.circular(10.0)
                  : Radius.zero,
              bottomRight: msg.userId != currentUser.uid
                  ? Radius.circular(10.0)
                  : Radius.zero,
            ),
          ),
          child: Column(
            crossAxisAlignment: msg.userId != currentUser.uid
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                msg.userId == currentUser.uid && currentUser.uid.isNotEmpty
                    ? 'You'
                    : recipientName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12.0,
                ),
              ),
              msg.images != null && msg.images!.isNotEmpty
                  ? Container(
                      margin: EdgeInsets.only(top: 5.0),
                      child: Wrap(
                        children: msg.images!
                            .map(
                              (img) => InkWell(
                                onTap: () => _onChatImageTapped(context, img,
                                    msg.userId != currentUser.uid),
                                child: Container(
                                  height: 100.0,
                                  width: 150.0,
                                  padding: msg.images!.length > 1
                                      ? EdgeInsets.all(5.0)
                                      : null,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    image: DecorationImage(
                                      image: CachedNetworkImageProvider(img),
                                      scale: 1.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: 2.0),
              msg.message != null && msg.message!.isNotEmpty
                  ? Text(
                      msg.message ?? '',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    )
                  : SizedBox(),
            ],
          ),
        ),
        Text(
          timeago.format(msg.dateCreated ?? DateTime.now()),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.0,
          ),
        ),
      ],
    ),
  );
}

_onChatImageTapped(BuildContext context, String imgUrl, bool showDownload) {
  SizeConfig().init(context);
  showGeneralDialog(
    context: context,
    pageBuilder: (ctx, _, __) {
      return Container(
        height: SizeConfig.screenHeight,
        width: SizeConfig.screenWidth,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(imgUrl),
            ),
            Positioned(
              top: 15.0 + SizeConfig.paddingTop,
              right: 15.0,
              child: Row(
                children: [
                  Visibility(
                    visible: showDownload,
                    child: GestureDetector(
                      onTap: () async {
                        final downloaded =
                            await _saveNetworkImage(context, imgUrl);
                        if (downloaded != null && downloaded == true) {
                          showSnackbar(
                              ctx, 'Image successfully saved to Gallery');
                        } else {
                          showSnackbar(ctx, 'Unable to save image in Gallery');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(8.0),
                        child: Icon(FontAwesomeIcons.download,
                            color: kBackgroundColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(8.0),
                      child:
                          Icon(FontAwesomeIcons.times, color: kBackgroundColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<bool?> _saveNetworkImage(BuildContext context, String path) async {
  return await GallerySaver.saveImage(path, albumName: 'TapKat - Barter');
}
