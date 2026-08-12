import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FormImagePicker extends StatefulWidget {
  final String label;
  final String? imageUrl;
  final String folder;
  final Function(String?) onImageSelected;
  final bool isUploading;

  const FormImagePicker({
    super.key,
    required this.label,
    this.imageUrl,
    required this.folder,
    required this.onImageSelected,
    this.isUploading = false,
  });

  @override
  State<FormImagePicker> createState() => _FormImagePickerState();
}

class _FormImagePickerState extends State<FormImagePicker> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image box container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            image: imageUrl != null && imageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _isUploading
              ? const Center(child: CircularProgressIndicator())
              : (imageUrl == null || imageUrl.isEmpty
                  ? IconButton(
                      icon: const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                      onPressed: _showImageSourceActionSheet,
                    )
                  : null),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (!_isUploading && (imageUrl == null || imageUrl.isEmpty))
          const Text(
            'No image selected',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Future<void> _showImageSourceActionSheet() async {
    if (_isUploading) return;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child('${widget.folder}/$fileName');

        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();

        if (mounted) {
          widget.onImageSelected(downloadUrl);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}