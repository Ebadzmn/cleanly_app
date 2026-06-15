class NetworkResponse<T> {
  final bool isSuccess;
  final int statusCode;
  final T? data;
  final String? message;

  NetworkResponse({
    required this.isSuccess,
    required this.statusCode,
    this.data,
    this.message,
  });

  @override
  String toString() {
    return 'NetworkResponse(isSuccess: $isSuccess, statusCode: $statusCode, data: $data, message: $message)';
  }
}
