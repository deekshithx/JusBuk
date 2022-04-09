import 'package:jusbuk/api/firebase_api.dart';
import 'package:jusbuk/model/firebase_file.dart';
import 'package:flutter/material.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({required this.file, Key? key}) : super(key: key);
  final FirebaseFile file;
  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  bool downlaoding = false;
  @override
  Widget build(BuildContext context) {
    bool isImage = ['.jpeg', '.jpg', '.png'].any(widget.file.name.contains);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: downlaoding
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                : const Icon(Icons.file_download),
            onPressed: () async {
              setState(() {
                downlaoding = true;
              });
              String path =
                  await FirebaseApi.downloadFile(widget.file.ref).then((value) {
                setState(() {
                  downlaoding = false;
                });
                return value;
              });

              final snackBar = SnackBar(
                content: Text('Downloaded ${widget.file.name} in $path'),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isImage
          ? Image.network(
              widget.file.url,
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
              height: double.infinity,
              fit: BoxFit.contain,
            )
          : const Center(
              child: Text(
                'Cannot be displayed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
