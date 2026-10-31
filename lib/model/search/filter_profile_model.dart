// To parse this JSON data, do
//
//     final filterProfileModel = filterProfileModelFromJson(jsonString);

import 'dart:convert';

import 'package:orange_ui/model/user/registration_user.dart';

FilterProfileModel filterProfileModelFromJson(String str) =>
    FilterProfileModel.fromJson(json.decode(str));

String filterProfileModelToJson(FilterProfileModel data) =>
    json.encode(data.toJson());

class FilterProfileModel {
  bool status;
  String message;
  int? total;
  List<UserData> data;

  FilterProfileModel({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory FilterProfileModel.fromJson(dynamic json) {
    if (json is! Map) {
      return FilterProfileModel(status: false, message: '', total: 0, data: []);
    }
    return FilterProfileModel(
      status: json["status"] == true || json["status"] == 1 || json["status"] == 'true',
      message: json["message"]?.toString() ?? '',
      total: json["total"] is int ? json["total"] : int.tryParse(json["total"]?.toString() ?? ''),
      data: json["data"] != null && json["data"] is List
          ? List<UserData>.from((json["data"] as List)
              .where((x) => x != null)
              .map((x) => UserData.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}
