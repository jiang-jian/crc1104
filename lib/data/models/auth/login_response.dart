/// 登录响应模型
class LoginResponse {
  final String? token;
  final String? tokenName;
  final UserInfo? userInfo;

  LoginResponse({this.token, this.tokenName, this.userInfo});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String?,
      tokenName: json['tokenName'] as String?,
      userInfo: json['userInfo'] != null
          ? UserInfo.fromJson(json['userInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenName': tokenName,
      'userInfo': userInfo?.toJson(),
    };
  }
}

/// 用户信息模型
class UserInfo {
  final String? userId;
  final String? username;
  final String? cashierName;
  final String? merchantCode;

  UserInfo({this.userId, this.username, this.cashierName, this.merchantCode});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] as String?,
      username: json['username'] as String?,
      cashierName: json['cashierName'] as String?,
      merchantCode: json['merchantCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'cashierName': cashierName,
      'merchantCode': merchantCode,
    };
  }
}
