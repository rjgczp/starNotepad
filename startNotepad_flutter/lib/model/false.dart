//{error: Key: 'LoginRequest.Username' Error:Field validation for 'Username' failed on the 'required' tag, message: 请求参数错误, success: false}
class False {
  final String error;
  final String message;
  final bool success;

  False({required this.error, required this.message, required this.success});

  factory False.fromJson(Map<String, dynamic> json) {
    return False(
      error: json['error'],
      message: json['message'],
      success: json['success'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'error': error, 'message': message, 'success': success};
  }
}
