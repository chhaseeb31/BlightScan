import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/cloudinary_service.dart';

class ProfilePhotoAvatar extends StatefulWidget {
  const ProfilePhotoAvatar({super.key, required this.radius});
  final double radius;
  @override
  State<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends State<ProfilePhotoAvatar> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await context.read<AuthSessionService>().loadProfilePhoto();
      } catch (_) {/* Keep the avatar usable when offline. */}
    });
  }

  Future<void> _pickPhoto() async {
    final session = context.read<AuthSessionService>();
    final uid = session.currentUser?.uid;
    if (_busy || uid == null) return;
    setState(() => _busy = true);
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85);
      if (image == null || session.currentUser?.uid != uid) return;
      final url = await CloudinaryService().uploadImage(File(image.path));
      if (url == null) throw StateError('Image upload failed.');
      await session.saveProfilePhoto(uid, url);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not save your profile picture. Check your connection and try again.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = context.watch<AuthSessionService>().photoUrl;
    final fallback =
        Icon(Icons.person, size: widget.radius, color: AppColors.primary);
    return Tooltip(
      message: 'Change profile picture',
      child: InkWell(
        onTap: _busy ? null : _pickPhoto,
        customBorder: const CircleBorder(),
        child: Stack(alignment: Alignment.bottomRight, children: [
          CircleAvatar(
              radius: widget.radius,
              backgroundColor: AppColors.primarySurface,
              child: ClipOval(
                  child: url == null
                      ? fallback
                      : Image.network(url,
                          width: widget.radius * 2,
                          height: widget.radius * 2,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => fallback))),
          CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.edit, size: 18, color: Colors.white)),
        ]),
      ),
    );
  }
}
