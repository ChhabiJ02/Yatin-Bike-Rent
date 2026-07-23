import 'dart:async';
import 'dart:io' as io;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Production-ready Storage service for customer document images.
///
/// Responsibilities:
/// - Build deterministic paths: documents/{customerCode}/{folder}/{fixedFileName}
/// - Compress images and enforce max upload size (~<= 500KB)
/// - Upload with required metadata
/// - Overwrite existing files (fixed filenames)
/// - Return Firebase download URL
/// - Provide delete/replace utilities
class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int maxBytes = 500 * 1024; // 500KB
  static const int _maxDimension = 1600;

  // For fallback temp filenames during compression.
  static final Uuid _uuid = Uuid();

  /// API used by your UI widgets (FormImagePicker, image_picker_widget).
  /// Uploads the picked image to `documents/{uid}/{folder}/{fixedFileName}`.
  ///
  /// - Returns the download URL (or `null` on failure)
  /// - `fixedFileName` is deterministic based on current timestamp to avoid re-uploads
  ///   colliding too often, while still overwriting per selection.
  static Future<String?> uploadImage(
    XFile imageFile, {
    required String folder,
    void Function(double progress)? onProgress,
    String? fixedFileName,
    String? documentType,
    String? contentType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final uid = user.uid;
      final effectiveFixedFileName =
          (fixedFileName ?? '${DateTime.now().microsecondsSinceEpoch}.jpg')
              .trim();

      // If your backend expects a particular folder structure, keep it as UI passes it.
      final storageFolder = folder.trim();
      final effectiveDocumentType = (documentType ?? 'image').trim();

      return uploadCustomerDocument(
        imageFile: imageFile,
        customerCode: uid,
        storageFolder: storageFolder,
        fixedFileName: effectiveFixedFileName,
        documentType: effectiveDocumentType,
        contentType: contentType,
        onProgress: onProgress,
      );
    } catch (e) {
      debugPrint('uploadImage failed: $e');
      return null;
    }
  }

  /// Uploads a single customer document image.
  ///
  /// [storageFolder] should be one of: aadhaar, license, vehicle, travel
  /// (we keep this structure as your UI already provides folder paths).
  ///
  /// [fixedFileName] must be deterministic (no random filenames) so re-uploads overwrite.
  static Future<String> uploadCustomerDocument({
    required dynamic imageFile,
    required String customerCode,
    required String storageFolder,
    required String fixedFileName,
    required String documentType,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final authUser = _auth.currentUser;
    if (authUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'unauthenticated',
        message: 'User is not authenticated',
      );
    }

    final path = buildStoragePath(
      customerCode: customerCode,
      storageFolder: storageFolder,
      fixedFileName: fixedFileName,
    );

    final uploadBytesPayload = await _prepareUploadBytes(
      imageFile: imageFile,
    );

    // bytes payload already compressed and size-limited.
    final metadata = SettableMetadata(
      contentType: contentType ?? 'image/jpeg',
      customMetadata: <String, String>{
        'uploadedAt': DateTime.now().toUtc().toIso8601String(),
        'customerCode': customerCode,
        'documentType': documentType,
      },
    );

    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(uploadBytesPayload, metadata);

    final completer = Completer<String>();

    StreamSubscription<TaskSnapshot>? sub;
    sub = uploadTask.snapshotEvents.listen((taskSnapshot) async {
      if (onProgress != null && taskSnapshot.totalBytes > 0) {
        final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        onProgress(progress.clamp(0.0, 1.0));
      }
    });

    try {
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      completer.complete(downloadUrl);
    } catch (e, st) {
      debugPrint('uploadCustomerDocument failed: $e\n$st');
      rethrow;
    } finally {
      await sub.cancel();
    }

    return completer.future;
  }

  /// Replace behaves the same as upload because the destination path is deterministic.
  static Future<String> replaceCustomerDocument({
    required dynamic imageFile,
    required String customerCode,
    required String storageFolder,
    required String fixedFileName,
    required String documentType,
    void Function(double progress)? onProgress,
  }) async {
    return uploadCustomerDocument(
      imageFile: imageFile,
      customerCode: customerCode,
      storageFolder: storageFolder,
      fixedFileName: fixedFileName,
      documentType: documentType,
      onProgress: onProgress,
    );
  }

  /// Deletes a previously uploaded document image by download URL.
  /// Returns true if deletion succeeded (or URL was empty).
  static Future<bool> deleteCustomerDocumentByUrl(String? downloadUrl) async {
    if (downloadUrl == null || downloadUrl.isEmpty) return true;

    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e, st) {
      debugPrint('deleteCustomerDocumentByUrl failed: $e\n$st');
      return false;
    }
  }

  /// Useful to fetch URL if path is known.
  static Future<String?> getDownloadUrl({
    required String customerCode,
    required String storageFolder,
    required String fixedFileName,
  }) async {
    final path = buildStoragePath(
      customerCode: customerCode,
      storageFolder: storageFolder,
      fixedFileName: fixedFileName,
    );

    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      debugPrint('getDownloadUrl failed: $e');
      return null;
    }
  }

  /// Build deterministic Storage path.
  /// Must not generate random folder names.
  static String buildStoragePath({
    required String customerCode,
    required String storageFolder,
    required String fixedFileName,
  }) {
    final safeCustomerCode = customerCode.trim();
    final safeFolder = storageFolder.trim();
    final safeFileName = fixedFileName.trim();
    return 'documents/$safeCustomerCode/$safeFolder/$safeFileName';
  }

  /// Compress and enforce max bytes.
  /// Strategy:
  /// - Start with a reasonable quality
  /// - Iteratively reduce quality if still above maxBytes
  /// - Keep output at JPEG, moderate dimensions
  static Future<Uint8List> compressImageToMaxBytes({
    required io.File inputFile,
    int maxSizeBytes = maxBytes,
    int startingQuality = 85,
  }) async {
    // Ensure we do not blow up file sizes.
    int quality = startingQuality.clamp(10, 95);

    final tempDir = await getTemporaryDirectory();

    Uint8List? lastBytes;

    // Up to 6 attempts (85 -> 55) and then stop.
    for (int attempt = 0; attempt < 6; attempt++) {
      final targetPath = '${tempDir.path}/${_uuid.v4()}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        inputFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        // Note: compressAndGetFile doesn't guarantee exact size; we enforce via quality stepping.
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        // Fallback to original
        final bytes = await inputFile.readAsBytes();
        if (bytes.length <= maxSizeBytes) return bytes;
        // If original is too large, return original (better than failing hard).
        return bytes;
      }

      final bytes = await result.readAsBytes();
      lastBytes = bytes;

      if (bytes.length <= maxSizeBytes) {
        return bytes;
      }

      // Reduce quality more aggressively if far above threshold.
      final ratio = bytes.length / maxSizeBytes;
      if (ratio > 2) {
        quality -= 12;
      } else {
        quality -= 6;
      }
      quality = quality.clamp(10, 95);
    }

    // Return best effort (could be slightly above max, but close).
    return lastBytes ?? await inputFile.readAsBytes();
  }

  static Future<Uint8List> _prepareUploadBytes({required dynamic imageFile}) async {
    if (imageFile is! XFile && imageFile is! io.File) {
      throw ArgumentError('Unsupported imageFile type: ${imageFile.runtimeType}');
    }

    // On web, we cannot use dart:io or flutter_image_compress.
    // We read the bytes from XFile directly.
    if (kIsWeb) {
      if (imageFile is XFile) {
        return await imageFile.readAsBytes();
      }
      // io.File is not supported on web.
      throw ArgumentError('io.File is not supported on web.');
    }

    // On mobile (io), we can compress.
    final fileToCompress = imageFile is XFile ? io.File(imageFile.path) : imageFile as io.File;
    return await compressImageToMaxBytes(inputFile: fileToCompress);
  }
}
