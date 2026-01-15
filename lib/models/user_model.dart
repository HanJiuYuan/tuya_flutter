import 'dart:convert';

class ThingSmartUserModel {
  /// The user's uid.
  final String uid;
  /// The user's username.
  final String username;

  /// The user's country code.
  final String countryCode;

  /// The user's email.
  final String email;

  /// The user's region code.
  final String regionCode;

  /// The user's phone number.
  final String phoneNumber;


  /// The user's nickname.
  final String nickname;

  /// The user's head icon URL.
  ///
  /// This is null if the user has not set a head icon.
  final String? headIconUrl;

  /// The users Temp Unit.
  final String tempUnit;

  /// The users Time Zone ID.
  final String timezoneId;

  /// The users Region From.
  final String regFrom;


  ThingSmartUserModel.fromJson(Map<String, dynamic> json)
      : uid = json['uid'],username = json['userName'],
        countryCode = json['countryCode'],
        email = json['email'],
        regionCode = json['regionCode'],
        phoneNumber = json['phoneNumber'],
        nickname = json['snsNickname'],
        headIconUrl = json['headIconUrl'].toString().isEmpty
            ? null
            : json['headIconUrl'].toString().startsWith('http')
                ? json['headIconUrl']
                : 'https://images.tuyaeu.com/${json['headIconUrl']}',
        tempUnit =json['tempUnit'],
        timezoneId = json['timezoneId'],
        regFrom = json['regFrom'];
  Map<String, dynamic> asMap() => {
    'username':username,
    'country_code':countryCode,
    'email': email ,
    'region_code': regionCode ,
    'phoneNumber': phoneNumber ,
    'nickname':nickname,
    'headIconUrl':headIconUrl,
    'tempUnit':tempUnit,
    'timezoneId':timezoneId,
    'regFrom':regFrom
  };
}
