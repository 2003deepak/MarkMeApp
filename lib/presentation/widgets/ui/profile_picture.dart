import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePicture extends StatefulWidget {
  final String? profilePicture;
  final Function(String? imagePath) onProfilePictureChanged;
  final BoxDecoration cardDecoration;
  final bool showChangeText;
  final double imageSize;
  final double cameraIconSize;

  const ProfilePicture({
    Key? key,
    required this.profilePicture,
    required this.onProfilePictureChanged,
    required this.cardDecoration,
    this.showChangeText = true,
    this.imageSize = 100,
    this.cameraIconSize = 36,
  }) : super(key: key);

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: const Text('Select where to pick the image from'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Immediately pass the local file path to parent
        // No upload simulation, just use the local path
        widget.onProfilePictureChanged(pickedFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated'),
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
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeProfilePicture() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Profile Picture'),
          content: const Text(
            'Are you sure you want to remove your profile picture?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onProfilePictureChanged(null);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile picture removed'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Profile Image Container
              Container(
                width: widget.imageSize,
                height: widget.imageSize,
                decoration: BoxDecoration(
                  gradient: widget.profilePicture == null
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(widget.imageSize / 2),
                  image: widget.profilePicture != null
                      ? DecorationImage(
                          image: _getImageProvider(widget.profilePicture!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.profilePicture == null
                    ? const Icon(Icons.person, color: Colors.white, size: 40)
                    : null,
              ),

              // Camera Icon for changing photo
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: widget.cameraIconSize,
                    height: widget.cameraIconSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(
                        widget.cameraIconSize / 2,
                      ),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

              // Remove icon (only shown when there's a profile picture)
              if (widget.profilePicture != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _removeProfilePicture,
                    child: Container(
                      width: widget.cameraIconSize * 0.7,
                      height: widget.cameraIconSize * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                          widget.cameraIconSize * 0.35,
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Change Photo Text
          if (widget.showChangeText)
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Text(
                widget.profilePicture != null
                    ? 'Change Profile Photo'
                    : 'Add Profile Photo',
                style: TextStyle(
                  color: const Color(0xFF4F46E5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      return FileImage(File(imageUrl));
    }
  }
}
