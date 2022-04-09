import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:jusbuk/page/image_page.dart';
import 'package:jusbuk/utils/widgets/custom_text_field.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jusbuk/api/firebase_api.dart';
import 'package:jusbuk/model/firebase_file.dart';
import 'package:jusbuk/model/firebase_folder.dart';
import 'package:jusbuk/page/app_drawer.dart';
import 'package:jusbuk/utils/jusbuk_utils.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.user, Key? key}) : super(key: key);
  final User user;
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<FirebaseFile>> futureFiles;
  late Future<List<FirebaseFolder>> futureFolders;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController fileNameController = TextEditingController();
  double _progress = 0;

  bool inHomePage = true,
      noFiles = false,
      noFolders = false,
      isOptionsOpen = false,
      isFileUploading = false,
      isLoading = false;
  String userPath = '';
  String currentPath = '';

  @override
  void initState() {
    super.initState();
    currentPath = 'files/${widget.user.uid}';
    userPath = 'files/${widget.user.uid}';
    futureFiles = FirebaseApi.listAllFiles(currentPath);
    futureFolders = FirebaseApi.listAllFolders(currentPath);
  }

  Future<bool> _handleNavPop() async {
    if (currentPath == '$userPath/' ||
        currentPath == userPath ||
        isOptionsOpen) {
      setState(() {
        isOptionsOpen = false;
      });
      return true;
    } else {
      List<String> c = currentPath.split('/');
      c.removeLast();
      goToDir(c.join('/'));
      return false;
    }
  }

  void goToDir(String path) {
    futureFiles = FirebaseApi.listAllFiles(path);
    futureFolders = FirebaseApi.listAllFolders(path);
    currentPath = path;
    setState(() {});
  }

  Future createFolder(context) async {
    // setState(() {
    //   isLoading = true;
    // });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, state) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                hintText: 'Enter file name',
                controller: fileNameController,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                label: Text(
                  isLoading ? 'Please wait!...' : 'Create folder',
                  style: const TextStyle(fontSize: 24),
                ),
                onPressed: () async {
                  try {
                    state(() {
                      isLoading = true;
                    });
                    final File file =
                        await Utils.getImageFileFromAssets('new folder.png');
                    final fileName = basename(file.path);

                    final destination =
                        '$currentPath/${fileNameController.text}/$fileName';
                    var task = FirebaseApi.uploadFile(destination, file);

                    if (task == null) return;

                    await task.whenComplete(() {
                      state(() {
                        isLoading = false;
                      });
                    });
                    Navigator.pop(context);
                    goToDir(currentPath);
                  } on FirebaseException catch (e) {
                    Utils()
                        .showSnackBar(context, e.message ?? 'something wrong');
                    state(() {
                      isLoading = false;
                    });
                  }
                },
                icon: const Icon(Icons.create_new_folder),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(user: widget.user),
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                createFolder(context);
              },
              icon: const Icon(Icons.create_new_folder_outlined))
        ],
        title: Text(currentPath == '$userPath/' || currentPath == userPath
            ? 'JusBuk'
            : currentPath.replaceAll('files/${widget.user.uid}/', '')),
        centerTitle: true,
      ),
      floatingActionButton: isFileUploading
          ? null
          : FloatingActionButton(
              child: const Icon(Icons.attach_file),
              onPressed: () async {
                uploadFile(context);
              }),
      body: WillPopScope(
        onWillPop: _handleNavPop,
        child: isFileUploading
            ? Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        'Uploading file ${(_progress * 100).toStringAsFixed(0)}%, Please wait'),
                    const SizedBox(height: 10),
                    CircularProgressIndicator(
                      value: _progress,
                    )
                  ],
                ),
              )
            : SingleChildScrollView(
                child: noFiles && noFolders
                    ? const Center(child: Text('\n\n\n\nThis folder is empty'))
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 14),
                        child: Column(
                          children: [
                            showFolders(),
                            showFiles(),
                          ],
                        ),
                      ),
              ),
      ),
    );
  }

  Future uploadFile(BuildContext context) async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;
    final String path = result.files.single.path ?? '';
    if (path.isNotEmpty) {
      final File file = File(path);
      final fileName = basename(file.path);
      final destination = '$currentPath/$fileName';
      UploadTask? task = FirebaseApi.uploadFile(destination, file);

      setState(() {
        isFileUploading = true;
      });

      if (task == null) return;
      task.snapshotEvents.listen((event) {
        setState(() {
          _progress =
              event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
        });
        if (event.state == TaskState.success) {
          _progress = 0;
        }
      }).onError((error) {
        // do something to handle error
      });

      final snapshot = await task.whenComplete(() {
        setState(() {
          isFileUploading = false;
        });
      });

      final urlDownload = await snapshot.ref.getDownloadURL();
      await Clipboard.setData(ClipboardData(text: urlDownload));
      Utils().showSnackBar(
          context, 'Sucessfully Uploaded, Url copied to ur clipboard');
      goToDir(currentPath);
    } else {
      Utils().showSnackBar(context, 'No File found');
    }
  }

  Widget showFiles() {
    return FutureBuilder<List<FirebaseFile>>(
      future: futureFiles,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center();
          default:
            if (snapshot.hasError) {
              return const Center(child: Text('Some error occurred!'));
            } else {
              final files = snapshot.data!;
              if (files.isEmpty) {
                return const Center(
                  child: Text(
                      '\n\n\n\n\n\nNo files found!,\nUpload by clicking the button below',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16)),
                );
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];

                  return buildFilesView(context, file);
                },
              );
            }
        }
      },
    );
  }

  Widget showFolders() {
    return FutureBuilder<List<FirebaseFolder>>(
      future: futureFolders,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const Center(child: CircularProgressIndicator());
          default:
            if (snapshot.hasError) {
              return const Center(child: Text('Some error occurred!'));
            } else {
              final files = snapshot.data!;
              if (files.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // buildHeader(files.length),
                  // const SizedBox(height: 12),
                  GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      //  return Text(file.name);
                      return buildFolderView(context, file);
                    },
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              );
            }
        }
      },
    );
  }

  Widget buildFilesView(BuildContext context, FirebaseFile file) =>
      GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ImagePage(file: file),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 100,
                child: Utils().isImage(file.fileType)
                    ? Image.network(
                        file.url,
                        fit: BoxFit.fill,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Utils().isVideo(file.fileType)
                        ? FutureBuilder<File>(
                            future: Utils().generateThumbnail(file.url),
                            builder: ((context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done ||
                                  snapshot.connectionState ==
                                      ConnectionState.active) {
                                return SizedBox(
                                    width: 100,
                                    height: 120,
                                    child: Image.file(
                                      snapshot.data!,
                                      fit: BoxFit.fitHeight,
                                    ));
                              } else {
                                return const CircularProgressIndicator();
                              }
                            }))
                        : Utils().isAudio(file.fileType)
                            ? Expanded(
                                child: Container(
                                color: Colors.grey,
                                child: const Icon(
                                  Icons.audiotrack,
                                  size: 40,
                                ),
                              ))
                            : Utils().isPdf(file.fileType)
                                ? Expanded(
                                    child: Container(
                                    color: Colors.orange,
                                    child: const Icon(
                                      Icons.file_copy,
                                      size: 40,
                                    ),
                                  ))
                                : Expanded(
                                    child: Container(
                                    color: Colors.grey,
                                    child: const Icon(
                                      Icons.error,
                                      size: 40,
                                    ),
                                  )),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.40,
              child: Row(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Utils().isImage(file.fileType)
                      ? Icon(
                          Icons.image,
                          color: Colors.blue[800],
                        )
                      : Utils().isVideo(file.fileType)
                          ? Icon(
                              Icons.ondemand_video_outlined,
                              color: Colors.amber[800],
                            )
                          : Utils().isAudio(file.fileType)
                              ? Icon(
                                  Icons.music_video_sharp,
                                  color: Colors.orange[800],
                                )
                              : Utils().isPdf(file.fileType)
                                  ? Icon(
                                      Icons.picture_as_pdf_outlined,
                                      color: Colors.green[800],
                                    )
                                  : Icon(
                                      Icons.sd_card_alert_outlined,
                                      color: Colors.red[900],
                                    ),
                  const SizedBox(width: 5),
                  Expanded(
                      child: Center(
                    child: Text(
                      file.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed:
                          isOptionsOpen ? null : showOptions(context, file)),
                ],
              ),
            ),
          ],
        ),
      );

  showOptions(BuildContext context, FirebaseFile file) {
    return () async {
      setState(() {
        isOptionsOpen = true;
      });
      showBottomSheet(
          enableDrag: false,
          context: context,
          builder: (context) {
            return Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(40)),
                  color: Colors.blue[50],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          color: Colors.black,
                        ),
                        width: 60,
                        height: 3,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Download'),
                      onTap: () async {
                        setState(() {
                          isOptionsOpen = false;
                        });
                        String path = await FirebaseApi.downloadFile(file.ref);

                        await Utils().showSnackBar(
                            context, 'Downloaded ${file.name} in $path');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.send_to_mobile_outlined),
                      title: const Text('Share a copy'),
                      onTap: () async {
                        String path = await FirebaseApi.downloadFile(file.ref);

                        await Share.shareFiles(
                          [path],
                        );
                        Navigator.pop(context);
                        setState(() {
                          isOptionsOpen = false;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.share),
                      title: const Text('Share url'),
                      onTap: () async {
                        String url = await file.ref.getDownloadURL();

                        await Share.share(url);
                        Navigator.pop(context);
                        setState(() {
                          isOptionsOpen = false;
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: const Text('Copy link'),
                      onTap: () async {
                        String url = await file.ref.getDownloadURL();
                        Navigator.pop(context);

                        await Clipboard.setData(ClipboardData(text: url));
                        Utils()
                            .showSnackBar(context, 'Url copied to clipboard');
                        setState(() {
                          isOptionsOpen = false;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_forever),
                      title: const Text('Delete'),
                      onTap: () async {
                        Navigator.pop(context);
                        await file.ref.delete();

                        goToDir(currentPath);
                        setState(() {
                          isOptionsOpen = false;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ));
          });
    };
  }
  // Widget buildFile(BuildContext context, FirebaseFile file) => ListTile(
  //       leading: ClipOval(
  //         child: Image.network(
  //           file.url,
  //           width: 52,
  //           height: 52,
  //           fit: BoxFit.cover,
  //         ),
  //       ),
  //       title: Text(
  //         file.name,
  //         style: TextStyle(
  //           fontWeight: FontWeight.bold,
  //           decoration: TextDecoration.underline,
  //           color: Colors.blue,
  //         ),
  //       ),
  //       onTap: () => Navigator.of(context).push(MaterialPageRoute(
  //         builder: (context) => ImagePage(file: file),
  //       )),
  //     );

  Widget buildFolderView(BuildContext context, FirebaseFolder file) =>
      GestureDetector(
        onTap: () {
          goToDir(file.ref.fullPath);
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  // height: 100,
                  child: const Icon(
                    Icons.folder,
                    size: 130,
                  )),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.40,
              child: Row(
                children: [
                  Expanded(
                      child: Center(
                    child: Text(
                      file.name,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  const IconButton(
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert_rounded),
                      onPressed: null),
                ],
              ),
            )
          ],
        ),
      );
}
