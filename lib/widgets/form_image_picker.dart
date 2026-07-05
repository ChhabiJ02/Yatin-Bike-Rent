import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class FormImagePicker extends StatefulWidget {
  final String label;
  final String? imageUrl;
  final String folder;
  final bool isRequired;
  final ValueChanged<String?> onImageSelected;
  final VoidCallback? onImageDeleted;

  const FormImagePicker({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.folder,
    required this.onImageSelected,
    this.onImageDeleted,
    this.isRequired = false,
  });

  @override
  State<FormImagePicker> createState() => _FormImagePickerState();
}

class _FormImagePickerState extends State<FormImagePicker> {
  double _uploadProgress = 0;
  bool _isUploading = false;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _localPath = widget.imageUrl;
  }

  @override
  void didUpdateWidget(FormImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _localPath = widget.imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              if (widget.isRequired)
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          _buildImageArea(),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    if (_isUploading) {
      return _buildUploadingState();
    }

    if (_localPath != null && _localPath!.isNotEmpty) {
      return _buildImagePreview();
    }

    return _buildUploadButton();
  }

  Widget _buildUploadingState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ember),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null),
          const SizedBox(height: 12),
          Text(
            _uploadProgress > 0
                ? 'Uploading ${(_uploadProgress * 100).toInt()}%'
                : 'Processing...',
            style: const TextStyle(color: AppColors.ember),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ember, width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _localPath!.startsWith('http')
                ? Image.network(
                    _localPath!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (_, _, _) => _buildPlaceholder(),
                  )
                : kIsWeb
                    ? _buildPlaceholder()
                    : Image.file(
                        File(_localPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _buildIconButton(
                  icon: Icons.camera_alt,
                  onTap: () => _pickImage(ImageSource.camera),
                  tooltip: 'Retake',
                ),
                const SizedBox(width: 8),
                if (widget.onImageDeleted != null)
                  _buildIconButton(
                    icon: Icons.delete,
                    onTap: _deleteImage,
                    tooltip: 'Delete',
                    isDestructive: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: AppColors.muted),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isDestructive = false,
  }) {
    return Material(
      color: isDestructive ? Colors.red : Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.ember.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Material(
        color: AppColors.ember.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: _showOptions,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 36, color: AppColors.ember),
              const SizedBox(height: 8),
              Text(
                'Tap to capture/select',
                style: TextStyle(
                  color: AppColors.ember,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.ember),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.ember),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0;
        });

        final url = await StorageService.uploadImage(
          pickedFile,
          folder: widget.folder,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _uploadProgress = progress);
            }
          },
        );

        if (mounted) {
          setState(() {
            _isUploading = false;
            _localPath = url;
          });

          if (url != null) {
            widget.onImageSelected(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _deleteImage() {
    setState(() {
      _localPath = null;
    });
    widget.onImageSelected(null);
    widget.onImageDeleted?.call();
  }
}