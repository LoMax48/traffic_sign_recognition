import 'dart:convert';

import 'package:flutter_traffic_signs/models/sign_model.dart';

class SettingsModel {
  late final List<SignModel> signs;

  SettingsModel({required this.signs});

  SettingsModel.fromJson(Map<String, dynamic> json) {
    signs = (jsonDecode(json['signs']) as List)
        .map((sign) => SignModel.fromJson(sign))
        .toList();
  }

  Map<String, dynamic> toJson() {
    var data = jsonEncode(signs.map((e) => e.toJson()).toList());
    return {'signs': data};
  }
}
