import '../../core/utils/parse_utils.dart';

class CallerModel {
  CallerModel({
    required this.id,
    this.name,
    this.phone,
    this.avatarUrl,
    this.age,
    this.about,
    this.isOnline = false,
    this.isBusy = false,
    this.canCall = false,
  });

  final int id;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final int? age;
  final String? about;
  final bool isOnline;
  final bool isBusy;
  final bool canCall;

  CallerModel copyWith({
    bool? isOnline,
    bool? isBusy,
    bool? canCall,
  }) {
    return CallerModel(
      id: id,
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
      age: age,
      about: about,
      isOnline: isOnline ?? this.isOnline,
      isBusy: isBusy ?? this.isBusy,
      canCall: canCall ?? this.canCall,
    );
  }

  factory CallerModel.fromJson(Map<String, dynamic> json) {
    final isBusy = json['is_busy'] == true || json['is_busy'] == 1;
    final balanceOk = json['can_call'] == true || json['can_call'] == 1;
    return CallerModel(
      id: JsonParse.toInt(json['id']),
      name: JsonParse.toStringOrNull(json['name']),
      phone: JsonParse.toStringOrNull(json['phone']),
      avatarUrl: JsonParse.toStringOrNull(json['avatar_url']),
      age: json['age'] == null ? null : JsonParse.toInt(json['age']),
      about: JsonParse.toStringOrNull(json['about']),
      isOnline: json['is_online'] == true || json['is_online'] == 1,
      isBusy: isBusy,
      canCall: balanceOk && !isBusy,
    );
  }
}
