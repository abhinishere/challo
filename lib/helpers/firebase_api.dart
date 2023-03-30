import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseApi {
  static UploadTask? uploadFile(String destination, File file) {
    try {
      final ref = FirebaseStorage.instance.ref(destination);

      return ref.putFile(
        file,
        SettableMetadata(
          customMetadata: null,
        ),
      );
    } on FirebaseException catch (e) {
      print(e);
      return null;
    }
  }
}
