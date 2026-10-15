import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/attachment_utils.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';
import 'package:livocal/theme/theme.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final User user;
  const ProfileEditScreen({super.key, required this.user});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late User _currentUser;
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  File? _newProfileImage;
  bool _isSaving = false;

  final List<String> _aboutPresets = [
    'Available',
    'Busy',
    'At school',
    'At the movies',
    'At work',
    'Battery about to die',
    'Can\'t talk, Livocal only',
    'In a meeting',
    'At the gym',
    'Sleeping',
    'Urgent calls only',
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _nameController = TextEditingController(text: _currentUser.name);
    final savedAbout = SharedPref.instance.getString('user_about') ??
        'Hey there! I am using Livocal.';
    _aboutController = TextEditingController(text: savedAbout);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _chooseImageSource() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await capturePhoto();
                  if (file != null && mounted) {
                    setState(() => _newProfileImage = file);
                    await _uploadAndSaveProfilePhoto(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await pickImageFromGallery();
                  if (file != null && mounted) {
                    setState(() => _newProfileImage = file);
                    await _uploadAndSaveProfilePhoto(file);
                  }
                },
              ),
              if (_currentUser.avatarUrl.isNotEmpty || _newProfileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() {
                      _newProfileImage = null;
                      _currentUser = _currentUser.copyWith(avatarUrl: '');
                    });
                    await _syncUserToStorageAndFirestore(_currentUser);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadAndSaveProfilePhoto(File file) async {
    setState(() => _isSaving = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${_currentUser.id}.jpg');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      _currentUser = _currentUser.copyWith(avatarUrl: downloadUrl);
      await _syncUserToStorageAndFirestore(_currentUser);

      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Profile photo updated successfully',
          type: SnacBarType.info,
        );
      }
    } catch (e) {
      debugPrint('Failed to upload profile photo: $e');
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Failed to upload photo online: $e',
          type: SnacBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncUserToStorageAndFirestore(User user) async {
    // 1. SharedPreferences
    await SharedPref.instance.setString('user', jsonEncode(user.toMap()));
    await SharedPref.instance.setString('user_about', _aboutController.text.trim());

    // 2. Local Isar
    await IsarDb.saveUser(user);

    // 3. Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update user on Firestore: $e');
    }
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _currentUser.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightBackground,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: const Text('Enter your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: 'Your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() {
                  _currentUser = _currentUser.copyWith(name: newName);
                });
                await _syncUserToStorageAndFirestore(_currentUser);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditAboutDialog() {
    final controller = TextEditingController(text: _aboutController.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.lightBackground,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: const Text('About'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 70,
                decoration: const InputDecoration(
                  hintText: 'About message',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select About',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _aboutPresets.length,
                  itemBuilder: (ctx, i) {
                    final preset = _aboutPresets[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(preset, style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        controller.text = preset;
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newAbout = controller.text.trim();
              if (newAbout.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() {
                  _aboutController.text = newAbout;
                });
                await SharedPref.instance.setString('user_about', newAbout);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final textTheme = Theme.of(context).custom.textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _currentUser);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: textTheme.titleLarge.copyWith(color: colorTheme.iconColor),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            // Center Avatar with edit badge
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: _newProfileImage != null
                        ? FileImage(_newProfileImage!)
                        : (_currentUser.avatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(_currentUser.avatarUrl)
                                as ImageProvider
                            : null),
                    child: (_newProfileImage == null && _currentUser.avatarUrl.isEmpty)
                        ? Text(
                            _currentUser.name.isNotEmpty
                                ? _currentUser.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  if (_isSaving)
                    const Positioned.fill(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _chooseImageSource,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Name Tile
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Name', style: TextStyle(color: Colors.grey, fontSize: 13)),
              subtitle: Text(
                _currentUser.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: _showEditNameDialog,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 72, right: 16, bottom: 16),
              child: Text(
                'This is not your username or pin. This name will be visible to your Livocal contacts.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const Divider(height: 1),

            // About / Status Tile
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About', style: TextStyle(color: Colors.grey, fontSize: 13)),
              subtitle: Text(
                _aboutController.text,
                style: const TextStyle(fontSize: 15),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: _showEditAboutDialog,
              ),
            ),
            const Divider(height: 1),

            // Phone Number Tile
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone', style: TextStyle(color: Colors.grey, fontSize: 13)),
              subtitle: Text(
                _currentUser.phone.getFormattedNumber(),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
