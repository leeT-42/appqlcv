class Label {
  String? id;
  String name;
  String userId;

  Label({this.id, required this.name, required this.userId});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'userId': userId,
      };

  factory Label.fromJson(Map<String, dynamic> json) => Label(
        id: json['id'],
        name: json['name'] ?? '',
        userId: json['userId'] ?? '',
      );
}


