import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/api_service.dart';
import '../core/providers/auth_provider.dart';
import '../core/theme/app_colors.dart';

class ProfilePhotoEditor extends ConsumerStatefulWidget {
  final String initials;
  final String avatarUrl;
  final double size;
  final double borderRadius;
  final bool showDeleteButton;
  final ValueChanged<String?> onAvatarChanged;
  final ValueChanged<String> onMessage;

  const ProfilePhotoEditor({
    super.key,
    required this.initials,
    required this.avatarUrl,
    required this.onAvatarChanged,
    required this.onMessage,
    this.size = 120,
    this.borderRadius = 999,
    this.showDeleteButton = true,
  });

  @override
  ConsumerState<ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends ConsumerState<ProfilePhotoEditor> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pickImage() async {
    if (_busy) return;

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _busy = true);
    try {
      final response = kIsWeb
          ? await ApiService.uploadAvatarBytes(
              await image.readAsBytes(),
              image.name,
            )
          : await ApiService.uploadAvatar(image.path);
      final data = response['data'] ?? {};
      final avatarUrl = data['avatarUrl']?.toString() ?? '';
      await ref.read(authProvider.notifier).updateUserAvatar(avatarUrl);
      widget.onAvatarChanged(avatarUrl);
      widget.onMessage(
        response['message'] ?? 'Foto profil berhasil diperbarui',
      );
    } catch (_) {
      widget.onMessage('Gagal mengunggah foto profil');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteImage() async {
    if (_busy || widget.avatarUrl.isEmpty) return;

    setState(() => _busy = true);
    try {
      final response = await ApiService.deleteAvatar();
      await ref.read(authProvider.notifier).updateUserAvatar(null);
      widget.onAvatarChanged(null);
      widget.onMessage(response['message'] ?? 'Foto profil berhasil dihapus');
    } catch (_) {
      widget.onMessage('Gagal menghapus foto profil');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiService.resolveFileUrl(widget.avatarUrl);

    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.accentHover],
                  ),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _Initials(
                          initials: widget.initials,
                          fontSize: widget.size / 3,
                        ),
                        errorWidget: (_, __, ___) => _Initials(
                          initials: widget.initials,
                          fontSize: widget.size / 3,
                        ),
                      )
                    : _Initials(
                        initials: widget.initials,
                        fontSize: widget.size / 3,
                      ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _busy ? null : _pickImage,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.showDeleteButton) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy || widget.avatarUrl.isEmpty ? null : _deleteImage,
            child: const Text(
              'Hapus Foto',
              style: TextStyle(color: Color(0xFFB91C1C)),
            ),
          ),
        ],
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  final double fontSize;

  const _Initials({required this.initials, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
