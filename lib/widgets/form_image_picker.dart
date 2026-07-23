
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:streetbike_rental/services/storage_service.dart';
import 'package:streetbike_rental/theme/app_theme.dart';

class FormImagePicker extends StatefulWidget {
  final String label;
  final String? imageUrl;
  final String folder;
  final bool isRequired;
  final Function(String? url) onImageSelected;

  const FormImagePicker({
    super.key,
    required this.label,
    this.imageUrl,
    required this.folder,
    this.isRequired = false,
    required this.onImageSelected,
  });

  @override
  State<FormImagePicker> createState() => _FormImagePickerState();
}

class _FormImagePickerState extends State<FormImagePicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _currentImageUrl;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(covariant FormImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      setState(() {
        _currentImageUrl = widget.imageUrl;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
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
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        setState(() => _isUploading = false);
        return;
      }

      final downloadUrl = await StorageService.uploadImage(
        image,
        folder: widget.folder,
        documentType: widget.label,
      );

      if (downloadUrl != null) {
        setState(() {
          _currentImageUrl = downloadUrl;
        });
        widget.onImageSelected(_currentImageUrl);
      } else {
        throw Exception('Upload failed, URL not received.');
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Upload failed. Please try again.';
      });
      debugPrint('Image picking/uploading failed: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _currentImageUrl != null
                ? Image.network(_currentImageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 50, color: Colors.grey),
            title: Text(widget.label),
            subtitle: _isUploading
                ? const LinearProgressIndicator()
                : Text(_currentImageUrl != null ? 'Image uploaded' : 'No image selected'),
            trailing: IconButton(
              icon: const Icon(Icons.upload_file, color: AppColors.ember),
              onPressed: _isUploading ? null : _showImageSourceDialog,
            ),
          ),
          if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _uploadError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          if (widget.isRequired && _currentImageUrl == null)
            const Padding(
              padding: EdgeInsets.only(top: 4.0, left: 16.0),
              child: Text(
                'This field is required.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}