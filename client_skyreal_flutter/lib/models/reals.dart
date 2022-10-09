class OwnReal {
  int id;
  int userFk;
  String frontPath;
  String backPath;
  String createdAt;
  int timespan;

  OwnReal(
      {required this.id,
      required this.userFk,
      required this.frontPath,
      required this.backPath,
      required this.createdAt,
      required this.timespan});

  factory OwnReal.fromJson(Map<String, dynamic> json) {
    return OwnReal(
        id: json['id'],
        userFk: json['userFk'],
        frontPath: json['frontPath'],
        backPath: json['backPath'],
        createdAt: json['createdAt'],
        timespan: json['timespan']);
  }
}

// Real with username
class Real extends OwnReal {
  String username;

  Real(
      {required int id,
      required int userFk,
      required String frontPath,
      required String backPath,
      required String createdAt,
      required int timespan,
      required this.username})
      : super(
            id: id,
            userFk: userFk,
            frontPath: frontPath,
            backPath: backPath,
            createdAt: createdAt,
            timespan: timespan);

  factory Real.fromJson(Map<String, dynamic> json) {
    return Real(
        id: json['id'],
        userFk: json['userFk'],
        frontPath: json['frontPath'],
        backPath: json['backPath'],
        createdAt: json['createdAt'],
        timespan: json['timespan'],
        username: json['username']);
  }
}

// class Real {
//   int id;
//   int userFk;
//   String username;
//   String createdAt;
//   String frontPath;
//   String backPath;

//   Real(this.id, this.userFk, this.username, this.createdAt, this.frontPath,
//       this.backPath);

//   Real.fromJson(Map<String, dynamic> json)
//       : id = json['id'],
//         userFk = json['userFk'],
//         username = json['username'],
//         createdAt = json['createdAt'],
//         frontPath = json['frontPath'],
//         backPath = json['backPath'];
// }
