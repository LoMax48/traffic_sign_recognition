class SignModel {
  late final String name;
  late final String fileName;

  SignModel({required this.name, required this.fileName});

  SignModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    fileName = json['fileName'];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fileName': fileName,
    };
  }
}
