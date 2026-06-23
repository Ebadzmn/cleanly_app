class ApiConfig {
  // static const String baseUrl = "https://cleanly.devdioxide.com/api";
  static const String baseUrl = "http://10.10.7.102:5000";

  static const String previousBaseUrl = "";
  static String buildUrl(String endpoint) {
    if (!endpoint.startsWith('/')) {
      endpoint = "/$endpoint";
    }
    return '$baseUrl$endpoint';
  }

  static String getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
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
      "AIzaSyA9SQetjbchWmEJVV1uKsl4Q_gQID3FGBQ";

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
}
