import 'package:flutter/services.dart';

/// HapticService - Provides haptic feedback for premium UX
/// Implements 2026 haptic standards for tactile feedback
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;

  void setEnabled(bool value) {
    _isEnabled = value;
  }

  /// Light haptic - for UI interactions (button taps, toggles)
  Future<void> lightImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic - for significant actions (navigation, success)
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic - for important events (scan success, errors)
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection haptic - for selection changes
  Future<void> selectionClick() async {
    if (!_isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrate pattern - for error/warning states
  Future<void> vibrate() async {
    if (!_isEnabled) return;
    await HapticFeedback.vibrate();
  }

  /// Success haptic pattern - triple light impact
  Future<void> success() async {
    if (!_isEnabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error haptic pattern - heavy impact + vibrate
  Future<void> error() async {
    if (!_isEnabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.vibrate();
  }

  /// Warning haptic - medium impact
  Future<void> warning() async {
    if (!_isEnabled) return;
    await HapticFeedback.mediumImpact();
  }
}

final hapticService = HapticService();
