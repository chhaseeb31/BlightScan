import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Shared unsigned image uploader. No Cloudinary API secret belongs in the app.
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client;
  final http.Client? _client;
  static final uploadEndpoint =
      Uri.parse('https://api.cloudinary.com/v1_1/nppmhtyz/image/upload');
  static const uploadPreset = 'jloxzriq';

  Future<String?> uploadImage(File imageFile) async {
    final client = _client ?? http.Client();
    try {
      if (!await imageFile.exists() || await imageFile.length() == 0)
        return null;
      final request = http.MultipartRequest('POST', uploadEndpoint)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = jsonDecode(response.body);
      final value = data is Map ? data['secure_url'] : null;
      final url = value is String ? Uri.tryParse(value) : null;
      return url != null && url.scheme == 'https' && url.host.isNotEmpty
          ? value as String
          : null;
    } catch (_) {
      return null;
    } finally {
      if (_client == null) client.close();
    }
  }
}
