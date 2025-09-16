import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_button.dart';
import '../../widgets/profile/photo_grid.dart';
import '../../widgets/profile/profile_form.dart';
import '../../../domain/entities/user_profile.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _jobController = TextEditingController();
  final _companyController = TextEditingController();
  final _schoolController = TextEditingController();

  List<String> _selectedInterests = [];
  String _selectedGender = 'Woman';
  String _selectedPreference = 'Men';
  List<String> _photos = [];
  bool _hasPopulatedFields = false;

  /// Gets the current user ID from the AuthBloc state
  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _jobController.dispose();
    _companyController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _populateFields(UserProfile profile) {
    _nameController.text = profile.name;
    _bioController.text = profile.bio;
    _ageController.text = profile.age.toString();
    _jobController.text = profile.job ?? '';
    _companyController.text = profile.company ?? '';
    _schoolController.text = profile.school ?? '';
    _selectedInterests = List.from(profile.interests);
    _selectedGender = profile.gender ?? '';
    _photos = profile.photos.map((photo) => photo.url).toList();
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProfile = UserProfile(
        id: _currentUserId ?? 'fallback-user-id',
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 18,
        photos: _photos.map((url) => ProfilePhoto(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: url,
          order: _photos.indexOf(url),
        )).toList(),
        interests: _selectedInterests,
        location: UserLocation(
          latitude: 0.0,
          longitude: 0.0,
          city: 'Current City',
        ),
        gender: _selectedGender,
        job: _jobController.text.trim(),
        company: _companyController.text.trim(),
        school: _schoolController.text.trim(),
        lookingFor: _selectedPreference,
        isOnline: true,
        lastSeen: DateTime.now(),
        verified: false,
      );

      context.read<ProfileBloc>().add(UpdateProfile(profile: updatedProfile));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state.updateStatus == ProfileStatus.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: PulseColors.success,
                  ),
                );
                Navigator.of(context).pop();
              } else if (state.updateStatus == ProfileStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error ?? 'Failed to update profile'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return TextButton(
                onPressed: state.updateStatus == ProfileStatus.loading
                    ? null
                    : _saveProfile,
                child: state.updateStatus == ProfileStatus.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            PulseColors.primary,
                          ),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: PulseColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PulseColors.primary),
              ),
            );
          }

          if (state.status == ProfileStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.error ?? 'Failed to load profile',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PulseButton(
                    text: 'Retry',
                    onPressed: () {
                      context.read<ProfileBloc>().add(LoadProfile());
                    },
                  ),
                ],
              ),
            );
          }

          if (state.profile != null && !_hasPopulatedFields) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _populateFields(state.profile!);
              setState(() {
                _hasPopulatedFields = true;
              });
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotosSection(),
                  const SizedBox(height: 24),
                  ProfileForm(
                    nameController: _nameController,
                    bioController: _bioController,
                    ageController: _ageController,
                    jobController: _jobController,
                    companyController: _companyController,
                    schoolController: _schoolController,
                    selectedGender: _selectedGender,
                    selectedPreference: _selectedPreference,
                    selectedInterests: _selectedInterests,
                    onGenderChanged: (value) => setState(() => _selectedGender = value),
                    onPreferenceChanged: (value) => setState(() => _selectedPreference = value),
                    onInterestsChanged: (interests) => setState(() => _selectedInterests = interests),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add up to 6 photos. The first photo will be your main profile picture.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        PhotoGrid(
          photos: _photos,
          onPhotosChanged: (photos) => setState(() => _photos = photos),
          maxPhotos: 6,
        ),
      ],
    );
  }
}
