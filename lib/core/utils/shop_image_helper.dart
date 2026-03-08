class ShopImageHelper {
  static String? getImage(Map<String, dynamic>? data) {
    if (data == null) return null;

    final pPhoto = data['primaryPhoto'] as String?;
    if (pPhoto != null && pPhoto.isNotEmpty) return pPhoto;

    final photos = data['photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first.toString();
      if (first.isNotEmpty) return first;
    }

    final imgUrl = data['imageUrl'] as String?;
    if (imgUrl != null && imgUrl.isNotEmpty) return imgUrl;

    return null;
  }
}
