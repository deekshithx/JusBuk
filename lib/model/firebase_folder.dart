import 'package:firebase_storage/firebase_storage.dart';

class FirebaseFolder {
  final Reference ref;
  final String name;
  final String path;

  const FirebaseFolder({
    required this.ref,
    required this.name,
    required this.path,
  });
}
