class Real {
  int id;
  int userFk;
  String username;
  String createdAt;
  String frontPath;
  String backPath;

  Real(this.id, this.userFk, this.username, this.createdAt, this.frontPath,
      this.backPath);

  Real.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userFk = json['userFk'],
        username = json['username'],
        createdAt = json['createdAt'],
        frontPath = json['frontPath'],
        backPath = json['backPath'];
}
