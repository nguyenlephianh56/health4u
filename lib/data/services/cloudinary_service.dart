// lib/data/services/cloudinary_service.dart
//
// Mô tả: Service upload ảnh lên Cloudinary qua REST API (unsigned upload).
// Không cần SDK riêng — chỉ dùng package http.
//
// Cách dùng:
//   final url = await CloudinaryService.uploadImage(imageFile);
//
// Cấu hình:
//   Vào file này, thay 3 hằng số bên dưới bằng thông tin Cloudinary của bạn.
//   Hướng dẫn lấy thông tin: xem README bên dưới.

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName    = 'dfvtfibtx';    // ← thay tại đây
  static const String _uploadPreset = 'health4u_preset'; // ← thay tại đây
  static const String _folder       = 'health4u/recipes';   // ← thay nếu muốn

  // ── Upload ảnh lên Cloudinary ─────────────────────────────────────────────
  // Trả về URL ảnh đã upload, hoặc throw Exception nếu thất bại.
  static Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    // Dùng multipart/form-data để gửi file
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder']        = _folder;

    // Đính kèm file ảnh
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    // Gửi request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      // Trả về secure_url (https)
      return data['secure_url'] as String;
    } else {
      final error = json.decode(response.body);
      throw Exception(
        'Upload Cloudinary thất bại: ${error['error']?['message'] ?? response.statusCode}',
      );
    }
  }
}

