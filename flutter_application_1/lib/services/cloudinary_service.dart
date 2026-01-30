import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // Cloudinary configuration
  static const String cloudName = 'dvtuiyqra';
  static const String uploadPreset = 'jsconstruct';
  static const String uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Upload image to Cloudinary using unsigned preset
  /// Returns the secure_url of the uploaded image
  Future<String> uploadImage(File file, {String folder = 'bookings'}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Add upload parameters
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final secureUrl = jsonResponse['secure_url'] as String;

        print('✅ Image uploaded to Cloudinary: $secureUrl');
        return secureUrl;
      } else {
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - $responseData',
        );
      }
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      rethrow;
    }
  }

  /// Upload image from bytes (for web or camera)
  Future<String> uploadImageBytes(
    List<int> bytes,
    String filename, {
    String folder = 'bookings',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      // Add upload parameters
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final secureUrl = jsonResponse['secure_url'] as String;

        print('✅ Image uploaded to Cloudinary: $secureUrl');
        return secureUrl;
      } else {
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - $responseData',
        );
      }
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      rethrow;
    }
  }
}
