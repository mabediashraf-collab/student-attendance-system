class ImageHelper {
  static String getFullImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';
    if (photoPath.startsWith('http')) return photoPath;
    // Remove any double slashes
    String cleanPath = photoPath.replaceAll('//', '/');
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    return 'http://localhost/sms_api/$cleanPath';
  }
  
  static String getDefaultAvatar(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}