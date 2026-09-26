class ApiConfig {
  static const String baseUrl = "https://api.cleanly.sbs";
  // static const String baseUrl = "http://10.10.26.200:5005";

  static const String previousBaseUrl = "";
  static String buildUrl(String endpoint) {
    if (!endpoint.startsWith('/')) {
      endpoint = "/$endpoint";
    }
    return '$baseUrl$endpoint';
  }

  static String getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";

    // Fix for Windows paths returned by backend
    url = url.replaceAll('\\', '/');

    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    if (url.startsWith("/")) {
      return "$baseUrl$url";
    }
    return "$baseUrl/$url";
  }

  static String buildUrlWithParams(
    String endpoint,
    Map<String, String> queryParams,
  ) {
    final uri = Uri.parse(buildUrl(endpoint));
    return uri.replace(queryParameters: queryParams).toString();
  }

  static const String googleMapsApiKey =
      "AIzaSyACqk7UtvTeomLZdT2MGpIoxw8VAkod3nk";

  static String? buildStreetViewUrl(
    String? lat,
    String? lng, {
    int width = 400,
    int height = 300,
    int fov = 90,
    int heading = 0,
    int pitch = 0,
  }) {
    if (lat == null || lat.isEmpty || lng == null || lng.isEmpty) {
      return null;
    }

    try {
      final double latValue = double.parse(lat);
      final double lngValue = double.parse(lng);

      return "https://maps.googleapis.com/maps/api/streetview?size=${width}x${height}&location=$latValue,$lngValue&key=$googleMapsApiKey&fov=$fov&heading=$heading&pitch=$pitch";
    } catch (e) {
      return null;
    }
  }

  static String? buildStaticMapUrl(
    String? lat,
    String? lng,
    String? address, {
    int width = 400,
    int height = 300,
    int zoom = 15,
  }) {
    final bool hasValidCoordinates =
        lat != null &&
        lat.trim().isNotEmpty &&
        lat.trim() != "0" &&
        lat.trim() != "0.0" &&
        lng != null &&
        lng.trim().isNotEmpty &&
        lng.trim() != "0" &&
        lng.trim() != "0.0";

    if (hasValidCoordinates) {
      try {
        final double latValue = double.parse(lat!.trim());
        final double lngValue = double.parse(lng!.trim());
        // OpenStreetMap raster render API
        return "https://static-maps.yandex.ru/1.x/?ll=$lngValue,$latValue&size=${width > 650 ? 650 : width},${height > 450 ? 450 : height}&z=$zoom&l=map";
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
