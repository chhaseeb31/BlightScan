import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/widgets/gs_app_bar.dart';
import '../../data/services/community_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final List<String> imageUrls = [];

    final success = await context.read<CommunityService>().createPost(
          caption: _captionController.text.trim(),
          imageUrls: imageUrls,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to create post. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GSAppBar(
        title: 'New Post',
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Post',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(authSession.displayName[0].toUpperCase()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'What\'s happening with your tomatoes?',
                      border: InputBorder.none,
                    ),
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_selectedImage!,
                        width: double.infinity, height: 300, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('Add Photo',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
