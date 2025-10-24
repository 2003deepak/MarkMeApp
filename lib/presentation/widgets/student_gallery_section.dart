import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StudentGallerySection extends StatefulWidget {
  final List<String?> gallery;
  final Function(int, String) onPickGalleryImage;
  final BoxDecoration cardDecoration;

  const StudentGallerySection({
    Key? key,
    required this.gallery,
    required this.onPickGalleryImage,
    required this.cardDecoration,
  }) : super(key: key);

  @override
  State<StudentGallerySection> createState() => _StudentGallerySectionState();
}

class _StudentGallerySectionState extends State<StudentGallerySection> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _openCamera(int index) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, // Force front camera
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Pass the local file path to parent immediately
        widget.onPickGalleryImage(index, pickedFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Photo added to gallery'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload photos (up to 4)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.gallery.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final imagePath = widget.gallery[index];
              return InkWell(
                onTap: () => _openCamera(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    image: imagePath != null
                        ? DecorationImage(
                            image: _getImageProvider(imagePath),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imagePath == null
                      ? const Center(
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: Color(0xFF4F46E5),
                            size: 24,
                          ),
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    } else {
      return FileImage(File(imagePath));
    }
  }
}
