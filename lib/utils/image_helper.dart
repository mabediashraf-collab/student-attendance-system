import 'package:flutter/foundation.dart';

class ImageHelper {
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    String cleanPath = path;
    
    // Remove any existing 'uploads/users/' or 'uploads/' prefix
    if (cleanPath.startsWith('uploads/users/')) {
      cleanPath = cleanPath.substring(13);
    } else if (cleanPath.startsWith('uploads/')) {
      cleanPath = cleanPath.substring(8);
    }
    
    // Also remove if it has double paths
    cleanPath = cleanPath.replaceAll('users/users/', 'users/');
    cleanPath = cleanPath.replaceAll('//', '/');
    
    return 'http://localhost/sms_api/uploads/users/$cleanPath';
  }
  
  static Map<String, String> getImageHeaders() {
    if (kIsWeb) {
      final port = Uri.base.port;
      return {'Origin': 'http://localhost:$port'};
    }
    return {};
  }
}
