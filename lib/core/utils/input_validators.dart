class InputValidators {
  InputValidators._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$',
  );

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please create a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Please enter your full name';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
}
