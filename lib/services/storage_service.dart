import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  static Future<String?> uploadImage(
    File imageFile, {
    required String folder,
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final compressedFile = await _compressImage(imageFile);
      if (compressedFile == null) return null;

      final name = fileName ?? '${_uuid.v4()}.jpg';
      final path = '$folder/$name';

      final uploadTask = _storage.ref().child(path).putFile(
            compressedFile,
            SettableMetadata(
              contentType: 'image/jpeg',
              cacheControl: 'public, max-age=31536000',
            ),
          );

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        if (onProgress != null) {
          final progress =
              taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          onProgress(progress);
        }
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl.toString();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  static Future<String?> uploadImageFromPath(
    String imagePath, {
    required String folder,
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;
    return uploadImage(
      file,
      folder: folder,
      fileName: fileName,
      onProgress: onProgress,
    );
  }

  static Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1200,
        minHeight: 1200,
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }

  static Future<bool> deleteImage(String? url) async {
    if (url == null || url.isEmpty) return true;
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  static Future<List<String>> uploadMultipleImages(
    List<File> files, {
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final url = await uploadImage(
        files[i],
        folder: folder,
        onProgress: (progress) {
          if (onProgress != null) {
            final totalProgress = (i + progress) / files.length;
            onProgress(totalProgress);
          }
        },
      );
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }
}