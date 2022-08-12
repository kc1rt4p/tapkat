import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:tapkat/utilities/auth_util.dart';

const allowedFormats = {'image/png', 'image/jpeg', 'video/mp4', 'image/gif'};

class SelectedMedia {
  const SelectedMedia(this.fileName, this.storagePath, this.bytes,
      [this.rawPath]);
  final String storagePath;
  final Uint8List bytes;
  final String? rawPath;
  final String fileName;
}

enum MediaSource {
  photoGallery,
  videoGallery,
  camera,
}

Future<List<SelectedMedia>?> selectMediaWithSourceBottomSheet({
  required BuildContext context,
  double? maxWidth,
  double? maxHeight,
  required bool allowPhoto,
  bool allowVideo = false,
  String pickerFontFamily = 'Roboto',
  Color textColor = const Color(0xFF111417),
  Color backgroundColor = const Color(0xFFF5F5F5),
  String? fileName,
  bool multipleImage = false,
}) async {
  final createUploadMediaListTile =
      (String label, MediaSource mediaSource) => ListTile(
            title: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                pickerFontFamily,
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            tileColor: backgroundColor,
            dense: false,
            onTap: () => Navigator.pop(
              context,
              mediaSource,
            ),
          );
  final mediaSource = await showModalBottomSheet<MediaSource>(
      context: context,
      backgroundColor: backgroundColor,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
              child: ListTile(
                title: Text(
                  'Choose Source',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.getFont(
                    pickerFontFamily,
                    color: textColor.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
                tileColor: backgroundColor,
                dense: false,
              ),
            ),
            const Divider(),
            if (allowPhoto && allowVideo) ...[
              createUploadMediaListTile(
                'Gallery (Photo)',
                MediaSource.photoGallery,
              ),
              const Divider(),
              createUploadMediaListTile(
                'Gallery (Video)',
                MediaSource.videoGallery,
              ),
            ] else if (allowPhoto)
              createUploadMediaListTile(
                'Gallery',
                MediaSource.photoGallery,
              )
            else
              createUploadMediaListTile(
                'Gallery',
                MediaSource.videoGallery,
              ),
            const Divider(),
            createUploadMediaListTile('Camera', MediaSource.camera),
            const Divider(),
            const SizedBox(height: 10),
          ],
        );
      });
  if (mediaSource == null) {
    return null;
  }
  return selectMedia(
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    isVideo: mediaSource == MediaSource.videoGallery ||
        (mediaSource == MediaSource.camera && allowVideo && !allowPhoto),
    mediaSource: mediaSource,
  );
}

Future<List<SelectedMedia>?> selectMedia({
  double? maxWidth,
  double? maxHeight,
  bool isVideo = false,
  MediaSource mediaSource = MediaSource.camera,
}) async {
  final picker = ImagePicker();
  final source = mediaSource == MediaSource.camera
      ? ImageSource.camera
      : ImageSource.gallery;
  print('X====> $source');
  final pickedMediaFuture = isVideo
      ? picker.pickVideo(source: source)
      : source == ImageSource.camera
          ? picker.pickImage(source: source)
          : picker.pickMultiImage();
  await pickedMediaFuture;
  final pickedMedia = source == ImageSource.camera
      ? await pickedMediaFuture != null
          ? [await pickedMediaFuture as XFile]
          : []
      : await pickedMediaFuture as List<XFile>?;
  if (pickedMedia == null || pickedMedia.isEmpty) return null;

  List<SelectedMedia> mediaList = [];

  await Future.forEach(pickedMedia, (media) async {
    final mediaBytes = await (media as XFile).readAsBytes();

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final _newFile = await changeFileNameOnly(File(media.path), timestamp);

    // final path = storagePath(currentUserUid, media.path, isVideo);
    mediaList.add(SelectedMedia(
        timestamp + '.jpg',
        _newFile.path.split('/').last + timestamp + '.jpg',
        _newFile.readAsBytesSync(),
        _newFile.path));
  });

  return mediaList;
  // print('current path: $path');
  // print('storage path: ${_newFile.path.split('/').last}');
  // return SelectedMedia(
  //     timestamp + '.jpg',
  //     _newFile.path.split('/').last + timestamp + '.jpg',
  //     _newFile.readAsBytesSync(),
  //     _newFile.path);
}

Future<File> changeFileNameOnly(File file, String newFileName) {
  var path = file.path;
  var lastSeparator = path.lastIndexOf(Platform.pathSeparator);
  final split = path.split(Platform.pathSeparator);
  var newPath = path.substring(0, lastSeparator + 1) +
      newFileName +
      '.' +
      split[split.length - 1].split('.')[1];
  return file.rename(newPath);
}

bool validateFileFormat(String filePath, BuildContext context) {
  if (allowedFormats.contains(mime(filePath))) {
    return true;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('Invalid file format: ${mime(filePath)}'),
    ));
  return false;
}

String storagePath(String uid, String filePath, bool isVideo) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  // Workaround fixed by https://github.com/flutter/plugins/pull/3685
  // (not yet in stable).
  final ext = isVideo ? 'mp4' : filePath.split('.').last;
  return 'users/$uid/uploads/$timestamp.$ext';
}

void showUploadMessage(BuildContext context, String message,
    {bool showLoading = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (showLoading)
              Padding(
                padding: EdgeInsetsDirectional.only(end: 10.0),
                child: CircularProgressIndicator(),
              ),
            Text(message),
          ],
        ),
      ),
    );
}
