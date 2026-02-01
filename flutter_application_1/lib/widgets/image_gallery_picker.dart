import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/project.dart';
import '../services/cloudinary_service.dart';

class ImageGalleryPicker extends StatefulWidget {
  final List<ProjectImage> initialImages;
  final Function(List<ProjectImage>) onImagesChanged;

  const ImageGalleryPicker({
    super.key,
    required this.initialImages,
    required this.onImagesChanged,
  });

  @override
  State<ImageGalleryPicker> createState() => _ImageGalleryPickerState();
}

class _ImageGalleryPickerState extends State<ImageGalleryPicker> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();

  List<ProjectImage> _images = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      for (int i = 0; i < pickedFiles.length; i++) {
        final file = File(pickedFiles[i].path);

        final url = await _cloudinary.uploadImage(file, folder: 'projects');

        _images.add(ProjectImage(url: url, alt: '${_images.length + 1}'));

        setState(() {
          _uploadProgress = (i + 1) / pickedFiles.length;
        });
      }

      setState(() {
        _isUploading = false;
      });

      widget.onImagesChanged(_images);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${pickedFiles.length} image(s) uploaded successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(_images);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
    widget.onImagesChanged(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Project Images',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _isUploading ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isUploading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 8),
                Text(
                  'Uploading... ${(_uploadProgress * 100).toInt()}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        if (_images.isEmpty && !_isUploading)
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'No images added yet',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _pickImages,
                    child: const Text('Add Images'),
                  ),
                ],
              ),
            ),
          ),
        if (_images.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderImages,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return Card(
                key: ValueKey(image.url),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drag_handle, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          image.url,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[800],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    index == 0 ? 'Primary Image' : 'Image ${index + 1}',
                    style: TextStyle(
                      fontWeight: index == 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    image.url.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeImage(index),
                  ),
                ),
              );
            },
          ),
        if (_images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tip: Drag to reorder. First image is the primary image.',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
      ],
    );
  }
}
