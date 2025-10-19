import 'dart:io';
import 'dart:typed_data';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Service for generating and managing audio waveform data
class WaveformGeneratorService {
  final Logger _logger = Logger();
  static const int defaultSampleRate = 44100;
  static const int defaultBarsCount = 40;

  /// Generate waveform data from an audio file
  /// Returns normalized amplitude values (0.0 to 1.0)
  Future<List<double>> generateWaveformFromFile(
    String filePath, {
    int barsCount = defaultBarsCount,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.e('Audio file does not exist: $filePath');
        return _generateDummyWaveform(barsCount);
      }

      // Read audio file bytes
      final bytes = await file.readAsBytes();

      // Extract audio samples
      final samples = await _extractAudioSamples(bytes);

      // Generate waveform bars
      final waveform = _generateWaveformBars(samples, barsCount);

      _logger.d('Generated waveform with $barsCount bars from $filePath');
      return waveform;
    } catch (e) {
      _logger.e('Error generating waveform: $e');
      return _generateDummyWaveform(barsCount);
    }
  }

  /// Generate waveform during recording in real-time
  /// Returns a stream of waveform data as recording progresses
  Stream<List<double>> generateWaveformDuringRecording(
    PlayerController playerController,
  ) async* {
    try {
      // Listen to player waveform updates
      await for (final waveformData
          in playerController.onCurrentExtractedWaveformData) {
        if (waveformData.isNotEmpty) {
          // Normalize waveform data
          final normalized = _normalizeWaveformData(waveformData);
          yield normalized;
        }
      }
    } catch (e) {
      _logger.e('Error streaming waveform during recording: $e');
    }
  }

  /// Cache waveform data locally
  Future<void> cacheWaveformData(
    String messageId,
    List<double> waveform,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/waveforms/$messageId.json');

      // Create directory if it doesn't exist
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      // Convert waveform to string and save
      final waveformString = waveform.join(',');
      await file.writeAsString(waveformString);

      _logger.d('Cached waveform for message $messageId');
    } catch (e) {
      _logger.e('Error caching waveform: $e');
    }
  }

  /// Get cached waveform data
  Future<List<double>?> getCachedWaveform(String messageId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/waveforms/$messageId.json');

      if (!await file.exists()) {
        return null;
      }

      final waveformString = await file.readAsString();
      final waveform = waveformString
          .split(',')
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();

      _logger.d('Retrieved cached waveform for message $messageId');
      return waveform;
    } catch (e) {
      _logger.e('Error getting cached waveform: $e');
      return null;
    }
  }

  /// Clear all cached waveform data
  Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final waveformsDir = Directory('${directory.path}/waveforms');

      if (await waveformsDir.exists()) {
        await waveformsDir.delete(recursive: true);
        _logger.d('Cleared waveform cache');
      }
    } catch (e) {
      _logger.e('Error clearing waveform cache: $e');
    }
  }

  // Private helper methods

  /// Extract audio samples from raw bytes
  Future<List<double>> _extractAudioSamples(Uint8List bytes) async {
    // Simple PCM extraction (assuming 16-bit audio)
    // This is a simplified version - in production you'd want proper audio decoding
    final samples = <double>[];

    for (int i = 0; i < bytes.length - 1; i += 2) {
      // Convert bytes to 16-bit signed integer
      final sample = (bytes[i + 1] << 8) | bytes[i];

      // Normalize to -1.0 to 1.0 range
      final normalized = sample / 32768.0;
      samples.add(normalized.abs()); // Use absolute value for visualization
    }

    return samples;
  }

  /// Generate waveform bars from audio samples
  List<double> _generateWaveformBars(List<double> samples, int barsCount) {
    if (samples.isEmpty) {
      return _generateDummyWaveform(barsCount);
    }

    final bars = <double>[];
    final samplesPerBar = samples.length ~/ barsCount;

    for (int i = 0; i < barsCount; i++) {
      final startIndex = i * samplesPerBar;
      final endIndex = (i + 1) * samplesPerBar;

      // Calculate RMS (Root Mean Square) for this segment
      double sum = 0;
      int count = 0;

      for (int j = startIndex; j < endIndex && j < samples.length; j++) {
        sum += samples[j] * samples[j];
        count++;
      }

      final rms = count > 0 ? (sum / count).clamp(0.0, 1.0) : 0.0;
      bars.add(rms);
    }

    // Normalize bars to 0.0-1.0 range
    final maxAmplitude = bars.reduce((a, b) => a > b ? a : b);
    if (maxAmplitude > 0) {
      return bars.map((bar) => bar / maxAmplitude).toList();
    }

    return bars;
  }

  /// Normalize waveform data from PlayerController
  List<double> _normalizeWaveformData(List<double> data) {
    if (data.isEmpty) return [];

    final maxAmplitude = data.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    if (maxAmplitude == 0) return data.map((e) => 0.0).toList();

    return data
        .map((value) => (value.abs() / maxAmplitude).clamp(0.0, 1.0))
        .toList();
  }

  /// Generate dummy waveform for testing or error states
  List<double> _generateDummyWaveform(int barsCount) {
    return List.generate(
      barsCount,
      (i) => (0.2 + (i % 5) * 0.15).clamp(0.0, 1.0),
    );
  }

  /// Generate realistic-looking random waveform (for loading states)
  List<double> generatePlaceholderWaveform(int barsCount) {
    final List<double> waveform = [];
    double previousValue = 0.3;

    for (int i = 0; i < barsCount; i++) {
      // Generate smooth variations
      final change = (previousValue * 0.3) - 0.15;
      previousValue = (previousValue + change).clamp(0.1, 0.9);
      waveform.add(previousValue);
    }

    return waveform;
  }

  /// Resample waveform to a specific number of bars
  List<double> resampleWaveform(
    List<double> originalWaveform,
    int targetBarsCount,
  ) {
    if (originalWaveform.length == targetBarsCount) {
      return originalWaveform;
    }

    final resampled = <double>[];
    final ratio = originalWaveform.length / targetBarsCount;

    for (int i = 0; i < targetBarsCount; i++) {
      final sourceIndex = (i * ratio).floor();
      if (sourceIndex < originalWaveform.length) {
        resampled.add(originalWaveform[sourceIndex]);
      } else {
        resampled.add(0.0);
      }
    }

    return resampled;
  }

  /// Apply smoothing to waveform data
  List<double> smoothWaveform(List<double> waveform, {int windowSize = 3}) {
    if (waveform.length < windowSize) return waveform;

    final smoothed = <double>[];

    for (int i = 0; i < waveform.length; i++) {
      final startIndex = (i - windowSize ~/ 2).clamp(0, waveform.length - 1);
      final endIndex = (i + windowSize ~/ 2).clamp(0, waveform.length - 1);

      double sum = 0;
      int count = 0;

      for (int j = startIndex; j <= endIndex; j++) {
        sum += waveform[j];
        count++;
      }

      smoothed.add(count > 0 ? sum / count : 0.0);
    }

    return smoothed;
  }
}
