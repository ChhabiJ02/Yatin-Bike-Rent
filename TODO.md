# TODO
- [x] Implement production-ready Firebase Storage document upload (fixed filenames, overwrite, compression <= 500KB, metadata, progress, retry).
- [ ] Enhance FormImagePicker: fullscreen preview, upload locking, delete-from-storage + remove Firestore URL, offline queue.
- [ ] Implement dedicated StorageService API: uploadCustomerDocument/deleteCustomerDocument/replaceCustomerDocument/getDownloadUrl/compressImage/buildStoragePath.
- [ ] Add role-based Firebase Storage security rules: Admin/Staff can read/write under `documents/{customerCode}/...`.
- [ ] Add required Flutter packages for offline queue / connectivity.
- [ ] Run `flutter analyze` and `flutter test` (or `flutter run` smoke) after edits.

