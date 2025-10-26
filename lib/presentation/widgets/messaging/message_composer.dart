import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/entities/message.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../theme/pulse_colors.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/services/permission_service.dart';
import '../common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Enhanced message composer with voice, attachments, and rich features
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.conversationId,
    required this.senderId,
    this.replyToMessage,
    this.onCancelReply,
  });

  final String conversationId;
  final String senderId;
  final Message? replyToMessage;
  final VoidCallback? onCancelReply;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _sendButtonController;
  late AnimationController _attachmentController;
  late Animation<double> _sendButtonScale;
  late Animation<double> _attachmentRotation;

  bool _isComposing = false;
  bool _isRecording = false;
  bool _showAttachments = false;
  Duration _recordingDuration = Duration.zero;

  // Media functionality
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _recordingTimer;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _attachmentController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );

    _attachmentRotation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _attachmentController, curve: Curves.easeInOut),
    );

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = _textController.text.trim().isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing = isComposing;
      });

      if (isComposing) {
        _sendButtonController.forward();
        context.read<MessagingBloc>().add(
          StartTyping(conversationId: widget.conversationId),
        );
      } else {
        _sendButtonController.reverse();
        context.read<MessagingBloc>().add(
          StopTyping(conversationId: widget.conversationId),
        );
      }
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showAttachments) {
      _hideAttachments();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<MessagingBloc>().add(
      SendMessage(
        conversationId: widget.conversationId,
        senderId: widget.senderId,
        content: text,
        type: MessageType.text,
        replyToMessageId: widget.replyToMessage?.id,
      ),
    );

    _textController.clear();
    _focusNode.unfocus();

    if (widget.replyToMessage != null) {
      widget.onCancelReply?.call();
    }
  }

  void _toggleAttachments() {
    setState(() {
      _showAttachments = !_showAttachments;
    });

    if (_showAttachments) {
      _attachmentController.forward();
      _focusNode.unfocus();
    } else {
      _attachmentController.reverse();
    }
  }

  void _hideAttachments() {
    if (_showAttachments) {
      setState(() {
        _showAttachments = false;
      });
      _attachmentController.reverse();
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      // Check and request microphone permission
      final hasPermission = await Permission.microphone.isGranted;
      if (!hasPermission) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (mounted) {
            PulseToast.error(
              context,
              message: 'Microphone permission required for voice recording',
            );
          }
          return;
        }
      }

      // Check if device can record
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          PulseToast.error(context, message: 'Recording permission denied');
        }
        return;
      }

      // Get recording path
      final directory = await getApplicationDocumentsDirectory();
      final recordingPath =
          '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _recordingPath = recordingPath;
      });
      _hideAttachments();

      // Start recording
      await _audioRecorder.start(config, path: recordingPath);

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        setState(() {
          _recordingDuration = Duration(
            seconds: _recordingDuration.inSeconds + 1,
          );
        });
      });

      if (mounted) {
        PulseToast.info(context, message: 'Voice recording started');
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(context, message: 'Failed to start recording: $e');
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    try {
      setState(() {
        _isRecording = false;
      });

      _recordingTimer?.cancel();

      // Stop recording and get the path
      final path = await _audioRecorder.stop();

      if (path != null && _recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          final duration = _recordingDuration.inSeconds;

          // Send voice message through BLoC
          if (mounted) {
            context.read<MessagingBloc>().add(
              SendMessage(
                conversationId: widget.conversationId,
                senderId: widget.senderId,
                content: 'Voice message',
                type: MessageType.audio,
                mediaUrl: _recordingPath,
              ),
            );
          }

          if (mounted) {
            PulseToast.success(
              context,
              message: 'Voice message sent (${duration}s)',
            );
          }
        } else {
          if (mounted) {
            PulseToast.error(context, message: 'Recording file not found');
          }
        }
      } else {
        if (mounted) {
          PulseToast.error(context, message: 'Failed to save recording');
        }
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(context, message: 'Failed to stop recording: $e');
      }
    } finally {
      setState(() {
        _recordingPath = null;
        _recordingDuration = Duration.zero;
      });
    }
  }

  Future<void> _cancelVoiceRecording() async {
    try {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer?.cancel();

      // Stop recording without saving
      await _audioRecorder.stop();

      // Delete the recording file if it exists
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _recordingPath = null;
      }

      if (mounted) {
        PulseToast.info(context, message: 'Voice recording cancelled');
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(context, message: 'Failed to cancel recording: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onSurfaceColor,
        border: Border(
          top: BorderSide(color: context.outlineColor, width: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Reply preview
            if (widget.replyToMessage != null) _buildReplyPreview(),

            // Main composer
            Padding(
              padding: const EdgeInsets.all(12),
              child: _isRecording
                  ? _buildVoiceRecorder()
                  : _buildTextComposer(),
            ),

            // Attachments panel
            if (_showAttachments) _buildAttachmentsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final message = widget.replyToMessage!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PulseColors.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: context.outlineColor, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: PulseColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PulseColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.onSurfaceVariantColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20),
            onPressed: widget.onCancelReply,
            color: context.onSurfaceVariantColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attachment button
        AnimatedBuilder(
          animation: _attachmentRotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _attachmentRotation.value * 2 * 3.14159,
              child: IconButton(
                icon: Icon(
                  _showAttachments ? Icons.close : Icons.add,
                  color: _showAttachments
                      ? PulseColors.primary
                      : context.onSurfaceVariantColor,
                ),
                onPressed: _toggleAttachments,
              ),
            );
          },
        ),

        // Text input
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send/Voice button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isComposing
              ? ScaleTransition(
                  scale: _sendButtonScale,
                  child: Container(
                    decoration: BoxDecoration(
                      color: PulseColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                )
              : GestureDetector(
                  onTapDown: (_) => _startVoiceRecording(),
                  onTapUp: (_) => _stopVoiceRecording(),
                  onTapCancel: _cancelVoiceRecording,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.outlineColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic,
                      color: context.onSurfaceVariantColor,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildVoiceRecorder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: context.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Recording indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: context.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Recording duration
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.errorColor,
            ),
          ),

          const Spacer(),

          // Cancel button
          GestureDetector(
            onTap: _cancelVoiceRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: context.errorColor, size: 20),
            ),
          ),

          const SizedBox(width: 12),

          // Send button
          GestureDetector(
            onTap: _stopVoiceRecording,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.errorColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send, color: context.onSurfaceColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: context.outlineColor, width: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.blue,
                onTap: () {
                  _handleCameraAttachment();
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.green,
                onTap: () {
                  _handleGalleryAttachment();
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.videocam,
                label: 'Video',
                color: context.errorColor,
                onTap: () {
                  _handleVideoAttachment();
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.location_on,
                label: 'Location',
                color: Colors.purple,
                onTap: () {
                  _handleLocationAttachment();
                  _hideAttachments();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                icon: Icons.insert_drive_file,
                label: 'Document',
                color: Colors.orange,
                onTap: () {
                  _handleDocumentAttachment();
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.music_note,
                label: 'Audio',
                color: Colors.teal,
                onTap: () {
                  _handleAudioAttachment();
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.person,
                label: 'Contact',
                color: Colors.indigo,
                onTap: () {
                  _handleContactAttachment();
                  _hideAttachments();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.gif,
                label: 'GIF',
                color: Colors.pink,
                onTap: () {
                  _handleGifPicker();
                  _hideAttachments();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.onSurfaceVariantColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSnackbar(String message) {
    if (mounted) {
      PulseToast.info(context, message: message);
    }
  }

  Future<void> _handleCameraAttachment() async {
    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.isGranted;
      if (!cameraStatus) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            PulseToast.error(context, message: 'Camera permission required');
          }
          return;
        }
      }

      // Take photo with camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80, // Compress to 80% quality
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        // Send image message
        if (mounted) {
          context.read<MessagingBloc>().add(
            SendMessage(
              conversationId: widget.conversationId,
              senderId: widget.senderId,
              content: 'Photo',
              type: MessageType.image,
              mediaUrl: image.path,
            ),
          );
        }

        if (mounted) {
          PulseToast.success(context, message: 'Photo sent');
        }
        _hideAttachments();
      }
    } catch (e) {
      if (mounted) {
        PulseToast.error(context, message: 'Failed to capture photo: $e');
      }
    }
  }

  Future<void> _handleGalleryAttachment() async {
    try {
      // Check storage permission
      final storageStatus = await Permission.storage.isGranted;
      if (!storageStatus) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnackbar('Storage permission required');
          return;
        }
      }

      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to 80% quality
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        // Send image message
        if (mounted) {
          context.read<MessagingBloc>().add(
            SendMessage(
              conversationId: widget.conversationId,
              senderId: widget.senderId,
              content: 'Image',
              type: MessageType.image,
              mediaUrl: image.path,
            ),
          );
        }

        _showSnackbar('Image sent');
        _hideAttachments();
      }
    } catch (e) {
      _showSnackbar('Failed to select image: $e');
    }
  }

  Future<void> _handleVideoAttachment() async {
    try {
      // Check camera permission for video recording
      final cameraStatus = await Permission.camera.isGranted;
      if (!cameraStatus) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          _showSnackbar('Camera permission required for video');
          return;
        }
      }

      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Show options for video recording or gallery selection
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Select Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text('Record Video'),
                onTap: () => Navigator.pop(dialogContext, 'record'),
              ),
              ListTile(
                leading: Icon(Icons.video_library),
                title: Text('Choose from Gallery'),
                onTap: () => Navigator.pop(dialogContext, 'gallery'),
              ),
            ],
          ),
        ),
      );

      if (result != null) {
        XFile? video;
        if (result == 'record') {
          video = await _imagePicker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(seconds: 30), // Limit to 30 seconds
          );
        } else {
          video = await _imagePicker.pickVideo(source: ImageSource.gallery);
        }

        if (video != null) {
          // Send video message
          if (mounted) {
            context.read<MessagingBloc>().add(
              SendMessage(
                conversationId: widget.conversationId,
                senderId: widget.senderId,
                content: 'Video',
                type: MessageType.video,
                mediaUrl: video.path,
              ),
            );
          }

          _showSnackbar('Video sent');
          _hideAttachments();
        }
      }
    } catch (e) {
      _showSnackbar('Failed to handle video: $e');
    }
  }

  Future<void> _handleLocationAttachment() async {
    try {
      // Request location permission using the consistent PermissionService pattern
      final permissionService = PermissionService();
      final hasPermission = await permissionService
          .requestLocationWhenInUsePermission(context);

      if (!hasPermission) {
        _showSnackbar(
          'Location permission is required to share your location.',
        );
        return;
      }

      _showSnackbar('Getting your location...');

      // Use the location service from service locator
      final position = await ServiceLocator.instance.location
          .getCurrentLocation();

      if (position == null) {
        _showSnackbar('Unable to get location. Please check permissions.');
        return;
      }

      // Send location message
      if (mounted) {
        context.read<MessagingBloc>().add(
          SendMessage(
            conversationId: widget.conversationId,
            senderId: widget.senderId,
            content: 'Location: ${position.latitude}, ${position.longitude}',
            type: MessageType.location,
            mediaUrl: 'geo:${position.latitude},${position.longitude}',
          ),
        );
      }

      _showSnackbar('Location shared');
      _hideAttachments();
    } catch (e) {
      _showSnackbar('Failed to get location: $e');
    }
  }

  Future<void> _handleDocumentAttachment() async {
    try {
      // Since file_picker isn't available, show info about document sharing
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Document Sharing'),
          content: Text(
            'Document sharing will be available in a future update. '
            'You can currently share images, videos, audio, and location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('OK'),
            ),
          ],
        ),
      );

      _showSnackbar('Document sharing coming soon');
      _hideAttachments();
    } catch (e) {
      _showSnackbar('Document feature not yet available');
    }
  }

  Future<void> _handleAudioAttachment() async {
    try {
      // Since we don't have file_picker, show a message about audio file selection
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Audio Files'),
          content: Text(
            'For audio messages, use the voice recorder button. '
            'Audio file selection will be available in a future update.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('OK'),
            ),
          ],
        ),
      );

      _showSnackbar('Use voice recorder for audio messages');
      _hideAttachments();
    } catch (e) {
      _showSnackbar('Audio file feature not yet available');
    }
  }

  Future<void> _handleContactAttachment() async {
    try {
      // Since contacts_service isn't available, show info about contact sharing
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Contact Sharing'),
          content: Text(
            'Contact sharing will be available in a future update. '
            'You can currently share images, videos, audio, and location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('OK'),
            ),
          ],
        ),
      );

      _showSnackbar('Contact sharing coming soon');
      _hideAttachments();
    } catch (e) {
      _showSnackbar('Contact feature not yet available');
    }
  }

  Future<void> _handleGifPicker() async {
    try {
      // Since we don't have a GIF picker library, show info about GIF sharing
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('GIF Sharing'),
          content: Text(
            'GIF sharing will be available in a future update. '
            'You can currently share images, videos, audio, and location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('OK'),
            ),
          ],
        ),
      );

      _showSnackbar('GIF sharing coming soon');
      _hideAttachments();
    } catch (e) {
      _showSnackbar('GIF feature not yet available');
    }
  }
}
