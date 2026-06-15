class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return "NetworkException: $message (Status Code: $statusCode)";
    }
    return "NetworkException: $message";
  }
}

class TimeoutException extends NetworkException {
  TimeoutException([String message = "Request timed out"]) : super(message);
}

class NoInternetException extends NetworkException {
  NoInternetException([String message = "No internet connection"]) : super(message);
}

class UnauthorizedException extends NetworkException {
  UnauthorizedException([String message = "Unauthorized access"]) : super(message, statusCode: 401);
}

class ServerException extends NetworkException {
  ServerException([String message = "Internal server error", int? statusCode]) : super(message, statusCode: statusCode);
}

class UnknownException extends NetworkException {
  UnknownException([String message = "An unknown error occurred"]) : super(message);
}
