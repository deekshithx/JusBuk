import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class Utils {
  bool isImage(String fileExtension) {
    return ['.jpeg', '.jpg', '.png', '.gif'].any(fileExtension.contains);
  }

  bool isVideo(String fileExtension) {
    return ['.mp4', '.mkv', '.mov'].any(fileExtension.contains);
  }

  bool isPdf(String fileExtension) {
    return ['.pdf', '.txt'].any(fileExtension.contains);
  }

  bool isAudio(String fileExtension) {
    return [
      '.mp3',
    ].any(fileExtension.contains);
  }

  Future launchURL(String _url) async {
    if (!await launch(_url)) throw 'Could not launch $_url';
  }

  Future<File> generateThumbnail(String url) async {
    final String? _path = await VideoThumbnail.thumbnailFile(
      video: url,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 50,
      quality: 50,
    );
    return File(_path ?? '');
  }

  static Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');
    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  Future showSnackBar(BuildContext context, String msg) async =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}
