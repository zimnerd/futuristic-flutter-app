import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../navigation/app_router.dart';
import '../../../data/models/ai_companion.dart';
import '../../blocs/ai_companion/ai_companion_bloc.dart';
import '../../blocs/ai_companion/ai_companion_event.dart';
import '../../blocs/ai_companion/ai_companion_state.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/common/pulse_toast.dart';
import '../../widgets/ai_companion/companion_card_widget.dart';
import '../../widgets/ai_companion/companion_creation_widget.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Main screen for AI Companion functionality
class AiCompanionScreen extends StatefulWidget {
  const AiCompanionScreen({super.key});

  @override
  State<AiCompanionScreen> createState() => _AiCompanionScreenState();
}

class _AiCompanionScreenState extends State<AiCompanionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AiCompanionBloc>().add(LoadUserCompanions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Companions'),
        actions: [
          IconButton(
            onPressed: () => _showCreateCompanionDialog(),
            icon: Icon(Icons.add),
            tooltip: 'Create New Companion',
          ),
        ],
      ),
      body: BlocBuilder<AiCompanionBloc, AiCompanionState>(
        builder: (context, state) {
          if (state is AiCompanionLoading) {
            return Center(child: PulseLoadingWidget());
          }

          if (state is AiCompanionError) {
            return PulseErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<AiCompanionBloc>().add(LoadUserCompanions());
              },
            );
          }

          if (state is AiCompanionLoaded) {
            return _buildCompanionsList(state);
          }

          return Center(child: PulseLoadingWidget());
        },
      ),
    );
  }

  Widget _buildCompanionsList(AiCompanionLoaded state) {
    if (state.companions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AiCompanionBloc>().add(LoadUserCompanions());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.companions.length,
        itemBuilder: (context, index) {
          final companion = state.companions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CompanionCardWidget(
              companion: companion,
              onTap: () => _navigateToChat(companion),
              onEdit: () => _showEditCompanionDialog(companion),
              onDelete: () => _showDeleteConfirmation(companion),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 80,
              color: context.outlineColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No AI Companions Yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first AI companion to get personalized dating advice and practice conversations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.onSurfaceVariantColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateCompanionDialog,
              icon: Icon(Icons.add),
              label: Text('Create Your First Companion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: context.onSurfaceColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCompanionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => BlocListener<AiCompanionBloc, AiCompanionState>(
        listener: (context, state) {
          if (state is AiCompanionCreated) {
            Navigator.pop(context);
            PulseToast.success(
              context,
              message:
                  'Companion "${state.companion.name}" created successfully!',
            );
          } else if (state is AiCompanionError) {
            PulseToast.error(context, message: 'Error: ${state.message}');
          }
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: context.onSurfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: BlocBuilder<AiCompanionBloc, AiCompanionState>(
              builder: (context, state) {
                final isCreating = state is AiCompanionCreating;

                return Stack(
                  children: [
                    CompanionCreationWidget(
                      scrollController: scrollController,
                      onCompanionCreated:
                          (
                            name,
                            personality,
                            appearance, {
                            CompanionGender? gender,
                            CompanionAge? ageGroup,
                            String? description,
                            List<String>? interests,
                            Map<String, dynamic>? voiceSettings,
                          }) {
                            context.read<AiCompanionBloc>().add(
                              CreateCompanion(
                                name: name,
                                personality: personality,
                                appearance: appearance,
                                gender: gender,
                                ageGroup: ageGroup,
                                description: description,
                                interests: interests,
                                voiceSettings: voiceSettings,
                              ),
                            );
                            // Note: No longer calling Navigator.pop() here -
                            // BlocListener will handle navigation on success
                          },
                    ),
                    if (isCreating)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: PulseColors.primary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Creating your AI companion...',
                                style: TextStyle(
                                  color: context.onSurfaceColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCompanionDialog(AICompanion companion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.onSurfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CompanionCreationWidget(
            scrollController: scrollController,
            existingCompanion: companion,
            onCompanionCreated:
                (
                  name,
                  personality,
                  appearance, {
                  CompanionGender? gender,
                  CompanionAge? ageGroup,
                  String? description,
                  List<String>? interests,
                  Map<String, dynamic>? voiceSettings,
                }) {
                  context.read<AiCompanionBloc>().add(
                    UpdateCompanion(
                      companionId: companion.id,
                      name: name,
                      personality: personality,
                      appearance: appearance,
                    ),
                  );
                  Navigator.pop(context);
                },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(AICompanion companion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Companion'),
        content: Text(
          'Are you sure you want to delete ${companion.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AiCompanionBloc>().add(
                DeleteCompanion(companion.id),
              );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: context.errorColor),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(AICompanion companion) async {
    await context.push(AppRoutes.aiCompanionChat, extra: companion);

    // Refresh companions list when returning from chat
    if (mounted) {
      context.read<AiCompanionBloc>().add(LoadUserCompanions());
    }
  }
}
