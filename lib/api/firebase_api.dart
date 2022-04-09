import 'dart:io';

import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:jusbuk/model/firebase_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jusbuk/model/firebase_folder.dart';

class FirebaseApi {
  static Future<List<String>> _getDownloadLinks(List<Reference> refs) =>
      Future.wait(refs.map((ref) => ref.getDownloadURL()).toList());

  static Future<List<FirebaseFile>> listAllFiles(String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    final result = await ref.listAll();

    final List<String> urls = await _getDownloadLinks(result.items);

    return urls
        .asMap()
        .map((index, url) {
          final ref = result.items[index];
          final name = ref.name;
          final file = FirebaseFile(
              ref: ref,
              name: name,
              url: url,
              fileType: "." + ref.name.split('.').last);

          return MapEntry(index, file);
        })
        .values
        .toList();
  }

  static Future<List<FirebaseFolder>> listAllFolders(String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    final result = await ref.listAll();
    List<Reference> folders = result.prefixes;

    List<FirebaseFolder> folderData = [];

    for (Reference folder in folders) {
      folderData.add(FirebaseFolder(
          ref: folder, name: folder.name, path: folder.fullPath));
    }

    return folderData;
  }

  static Future<Directory> getPathToDownload() async {
    return await DownloadsPathProvider.downloadsDirectory ??
        Directory('/storage/emulated/0/Download');
  }

  static Future<String> downloadFile(Reference ref) async {
    final Directory dir = await getPathToDownload();

    final file = File('${dir.path}/${ref.name}');

    await ref.writeToFile(file);
    return '${dir.path}/${ref.name}';
  }

  static UploadTask? uploadFile(String destination, File file) {
    try {
      final ref = FirebaseStorage.instance.ref(destination);

      return ref.putFile(file);
    } on FirebaseException catch (e) {
      print(e);
      return null;
    }
  }
}
