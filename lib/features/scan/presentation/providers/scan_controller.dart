import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_quality_checker.dart';
import '../../../../core/services/image_quality_classifier.dart';
import '../../../../core/services/image_quality_config.dart';
import '../../../../core/services/image_quality_result.dart';
import '../../../../core/repositories/plant_disease_repository.dart';
import '../../../../core/services/scan_history_service.dart';
import '../../domain/models/scan_result.dart';

enum ScanUIState { idle, preview, analyzing, qualityCheck }

class ScanController extends ChangeNotifier with WidgetsBindingObserver {
  final ScanHistoryService historyService;

  ScanController({required this.historyService}) {
    WidgetsBinding.instance.addObserver(this);
  }

  CameraController? _cameraController;
  bool _isInitialized = false;
  XFile? _capturedImage;
  ScanUIState _currentState = ScanUIState.idle;
  String? _initError;

  final ImageQualityChecker _qualityChecker = ImageQualityChecker(
    config: ImageQualityConfig.plantAnalysis,
  );
  final ImageQualityClassifier _qualityClassifier = ImageQualityClassifier(
    config: ImageQualityConfig.plantAnalysis,
  );

  ImageQualityResult? _qualityResult;
  ImageQualityClassification? _qualityClassification;
  bool _isBusy = false;

  double _analysisProgress = 0.0;
  String _statusMessage = 'Preparing image...';
  String _statusSubtitle = 'Preparing a precise diagnosis for your leaf';
  FlashMode _flashMode = FlashMode.off;

  Timer? _analysisTimer;
  bool _disposed = false;
  bool _isInitializing = false;
  bool _analysisInProgress = false;
  int _operationId = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _isActive(int operationId) => !_disposed && operationId == _operationId;

  // Getters
  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  XFile? get capturedImage => _capturedImage;
  ScanUIState get currentState => _currentState;
  String? get initError => _initError;
  ImageQualityResult? get qualityResult => _qualityResult;
  ImageQualityClassification? get qualityClassification =>
      _qualityClassification;
  bool get isBusy => _isBusy;
  double get analysisProgress => _analysisProgress;
  String get statusMessage => _statusMessage;
  String get statusSubtitle => _statusSubtitle;
  FlashMode get flashMode => _flashMode;

  Future<void> initializeCamera() async {
    if (_disposed || _isInitialized || _isInitializing) return;
    _isInitializing = true;
    try {
      final cameras = await availableCameras();
      if (_disposed) return;
      if (cameras.isNotEmpty) {
        final controller = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.nv21,
        );
        await controller.initialize();
        if (_disposed) {
          await controller.dispose();
          return;
        }
        _cameraController = controller;
        _isInitialized = true;
        _initError = null;
        _notify();
      } else {
        _initError = 'No cameras available on this device';
        _notify();
      }
    } catch (e) {
      if (_disposed) return;
      debugPrint('Camera initialization error: $e');
      _initError = 'Camera permission denied or camera unavailable';
      _isInitialized = false;
      _notify();
    } finally {
      _isInitializing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _operationId++;
        _disposeCameraForLifecycle();
        break;
      case AppLifecycleState.resumed:
        if (!_isInitialized &&
            !_isInitializing &&
            _currentState == ScanUIState.idle) {
          initializeCamera();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _disposeCameraForLifecycle() {
    final controller = _cameraController;
    _cameraController = null;
    _isInitialized = false;
    if (controller != null) unawaited(controller.dispose());
    _notify();
  }

  Future<void> toggleFlash() async {
    final controller = _cameraController;
    if (_disposed || controller == null || !_isInitialized) return;
    try {
      final newMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await controller.setFlashMode(newMode);
      if (_disposed || controller != _cameraController) return;
      _flashMode = newMode;
      await HapticFeedback.lightImpact();
      _notify();
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  Future<void> takePicture() async {
    final controller = _cameraController;
    if (_disposed || _isBusy || controller == null || !_isInitialized) return;
    final operationId = ++_operationId;
    try {
      _isBusy = true;
      _notify();
      await HapticFeedback.mediumImpact();

      final image = await controller.takePicture();
      if (!_isActive(operationId)) return;
      _capturedImage = image;
      _currentState = ScanUIState.qualityCheck;
      _notify();

      await _classifyImageQuality(image.path, operationId);
    } catch (e) {
      if (!_isActive(operationId)) return;
      debugPrint('Capture failed: $e');
      _isBusy = false;
      _notify();
      rethrow;
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  Future<void> pickFromGallery() async {
    if (_disposed || _isBusy) return;
    final operationId = ++_operationId;
    _isBusy = true;
    _notify();
    await HapticFeedback.lightImpact();

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null || !_isActive(operationId)) return;

      _capturedImage = XFile(pickedFile.path);
      _currentState = ScanUIState.qualityCheck;
      _notify();

      await _classifyImageQuality(pickedFile.path, operationId);
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  void retake() {
    if (_disposed) return;
    _operationId++;
    _analysisInProgress = false;
    _cancelAnalysis();
    _capturedImage = null;
    _qualityResult = null;
    _qualityClassification = null;
    _currentState = ScanUIState.idle;
    _analysisProgress = 0.0;
    _statusMessage = 'Preparing image...';
    _statusSubtitle = 'Preparing a precise diagnosis for your leaf';
    _notify();
  }

  Future<void> _classifyImageQuality(String imagePath, int operationId) async {
    try {
      if (kIsWeb) {
        _qualityClassification = const ImageQualityClassification(
          level: ImageQualityLevel.poor,
          metrics: [],
          suggestions: ['Web does not support quality analysis.'],
          processingTime: Duration.zero,
          isAcceptable: true,
        );
      } else {
        final bytes = await File(imagePath).readAsBytes();
        _qualityClassification = await _qualityClassifier.classify(
          bytes,
          fileName: imagePath.split('/').last,
        );
      }
      if (!_isActive(operationId)) return;
      _currentState = ScanUIState.preview;
      _notify();
    } catch (e) {
      if (!_isActive(operationId)) return;
      _currentState = ScanUIState.preview;
      _qualityClassification = ImageQualityClassification(
        level: ImageQualityLevel.poor,
        metrics: [],
        suggestions: ['Error analyzing image.'],
        processingTime: Duration.zero,
        isAcceptable: false,
        error: e.toString(),
      );
      _notify();
    }
  }

  Future<bool> prepareForAnalysis() async {
    if (_disposed || _isBusy || _analysisInProgress || _capturedImage == null) {
      return false;
    }
    final operationId = _operationId;
    _isBusy = true;
    _currentState = ScanUIState.qualityCheck;
    _analysisProgress = 0.0;
    _notify();

    try {
      if (kIsWeb) {
        _qualityResult = ImageQualityResult(
          imageId: 'web_placeholder',
          fileName: '',
          fileSizeBytes: 0,
          format: 'unknown',
          width: 0,
          height: 0,
          colorDepth: 0,
          metrics: const [],
          timestamp: DateTime.now(),
          processingTime: Duration.zero,
          isValid: true,
        );
      } else {
        final bytes = await File(_capturedImage!.path).readAsBytes();
        _qualityResult = await _qualityChecker.validateFromBytes(
          bytes,
          fileName: _capturedImage!.path.split('/').last,
        );
      }

      _notify();
      return _isActive(operationId);
    } finally {
      _isBusy = false;
      _notify();
    }
  }

  Future<ScanResult?> startAnalysis() async {
    if (_disposed || _analysisInProgress || _capturedImage == null) return null;
    final operationId = _operationId;
    _analysisInProgress = true;
    _isBusy = true;

    _currentState = ScanUIState.analyzing;
    _analysisProgress = 0.0;
    _notify();

    final analysisStartedAt = DateTime.now();
    _startProgressSimulation(operationId);

    try {
      final bytes = await File(_capturedImage!.path).readAsBytes();
      final analysis = await PlantDiseaseRepository().analyzeImage(bytes);

      if (!analysis.success ||
          analysis.prediction == null ||
          analysis.details == null) {
        throw Exception(analysis.errorMessage ?? 'Analysis failed.');
      }

      final prediction = analysis.prediction!;
      final details = analysis.details!;
      final isHealthy = prediction.isHealthy;

      final result = ScanResult(
        imagePath: _capturedImage!.path,
        diseaseName: isHealthy ? 'Healthy Tomato Leaf' : 'Tomato Late Blight',
        cropName: 'Tomato',
        confidenceScore: prediction.confidence,
        severity: isHealthy ? 'none' : details.severity.toLowerCase(),
        status: isHealthy ? 'healthy' : 'diseased',
        description: details.description,
      );

      final elapsed = DateTime.now().difference(analysisStartedAt);
      if (elapsed < const Duration(milliseconds: 700)) {
        await Future.delayed(const Duration(milliseconds: 700) - elapsed);
      }
      if (!_isActive(operationId)) return null;
      _completeProgressSimulation();
      await historyService.saveScan(result);
      if (!_isActive(operationId)) return null;
      return result;
    } catch (e) {
      if (!_isActive(operationId)) return null;
      _cancelAnalysis();
      _currentState = ScanUIState.preview;
      _notify();
      rethrow;
    } finally {
      _analysisInProgress = false;
      _isBusy = false;
      _notify();
    }
  }

  void _startProgressSimulation(int operationId) {
    _analysisTimer?.cancel();
    const interval = Duration(milliseconds: 40);

    final stages = [
      _ProgressStage(0.0, 0.15, 260, 'Preparing image...',
          'Preparing a precise diagnosis'),
      _ProgressStage(0.15, 0.35, 520, 'Checking quality...',
          'Evaluating lighting and focus'),
      _ProgressStage(
          0.35, 0.60, 680, 'Enhancing image...', 'Sharpening features'),
      _ProgressStage(0.60, 0.80, 900, 'Running AI...',
          'Comparing against detection model'),
      _ProgressStage(0.80, 0.95, 760, 'Detecting...', 'Identifying symptoms'),
      _ProgressStage(0.94, 0.96, 420, 'Finalizing...', 'Preparing results'),
    ];

    int currentStageIndex = 0;
    int stageTick = 0;

    _analysisTimer = Timer.periodic(interval, (timer) {
      if (!_isActive(operationId)) {
        timer.cancel();
        return;
      }
      stageTick++;

      final stage = stages[currentStageIndex];
      final stageTicks = stage.durationMs ~/ 40;

      _analysisProgress =
          stage.from + (stage.to - stage.from) * (stageTick / stageTicks);
      _statusMessage = stage.title;
      _statusSubtitle = stage.subtitle;

      if (stageTick >= stageTicks) {
        if (currentStageIndex < stages.length - 1) {
          currentStageIndex++;
          stageTick = 0;
        } else {
          timer.cancel();
        }
      }
      _notify();
    });
  }

  void _completeProgressSimulation() {
    _analysisTimer?.cancel();
    _analysisProgress = 1.0;
    _statusMessage = 'Analysis complete.';
    _statusSubtitle = 'Your results are ready.';
    _notify();
  }

  void _cancelAnalysis() {
    _analysisTimer?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _operationId++;
    WidgetsBinding.instance.removeObserver(this);
    _analysisTimer?.cancel();
    _analysisTimer = null;

    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) unawaited(controller.dispose());

    _capturedImage = null;
    _qualityResult = null;
    _qualityClassification = null;

    _isInitialized = false;
    _isBusy = false;
    _analysisProgress = 0.0;

    super.dispose();
  }
}

class _ProgressStage {
  final double from;
  final double to;
  final int durationMs;
  final String title;
  final String subtitle;

  _ProgressStage(
      this.from, this.to, this.durationMs, this.title, this.subtitle);
}
