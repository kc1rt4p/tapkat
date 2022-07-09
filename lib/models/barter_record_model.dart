class BarterRecordModel {
  String? id;
  String? userid1;
  String? userid2;
  bool? user1Accepted;
  bool? user2Accepted;
  String? u1P1Id;
  String? u1P1Name;
  double? u1P1Price;
  String? u2P1Id;
  String? u2P1Name;
  double? u2P1Price;
  String? proposedBy;
  DateTime? lastProposedDate;
  String? dealStatus;
  DateTime? dealDate;
  String? u1P1Image;
  String? u2P1Image;
  String? barterId;
  int? barterNo;
  String? userid1Role;
  String? userid2Role;
  String? userid1Name;
  String? userid2Name;
  List<String>? deletedFor;

  BarterRecordModel({
    this.id,
    this.userid1,
    this.userid2,
    this.user1Accepted,
    this.user2Accepted,
    this.u1P1Id,
    this.u1P1Name,
    this.u1P1Price,
    this.u2P1Id,
    this.u2P1Name,
    this.u2P1Price,
    this.proposedBy,
    this.lastProposedDate,
    this.dealStatus,
    this.dealDate,
    this.u1P1Image,
    this.u2P1Image,
    this.barterId,
    this.barterNo,
    this.userid1Role,
    this.userid2Role,
    this.userid1Name,
    this.userid2Name,
    this.deletedFor,
  });

  factory BarterRecordModel.fromJson(Map<String, dynamic> json) {
    return BarterRecordModel(
      id: json['id'],
      userid1: json['userid1'],
      userid2: json['userid2'],
      user1Accepted: json['user1Accepted'],
      user2Accepted: json['user2Accepted'],
      u1P1Id: json['u1P1Id'],
      u1P1Name: json['u1P1Name'],
      u1P1Price: json['u1P1Price'],
      u2P1Id: json['u2P1Id'],
      u2P1Name: json['u2P1Name'],
      u2P1Price: json['u2P1Price'],
      proposedBy: json['proposedBy'],
      lastProposedDate: json['lastProposedDate'],
      dealStatus: json['dealStatus'],
      dealDate: json['dealDate'] != null ? json['dealDate'].toDate() : null,
      u1P1Image: json['u1P1Image'],
      u2P1Image: json['u2P1Image'],
      barterId: json['barterId'],
      barterNo: json['barterNo'],
      userid1Role: json['userid1Role'],
      userid2Role: json['userid2Role'],
      userid1Name: json['userid1Name'],
      userid2Name: json['userid2Name'],
      deletedFor: json['deletedFor'] != null
          ? (json['deletedFor'] as List<dynamic>)
              .map((id) => id.toString())
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid1': this.userid1,
      'userid2': this.userid2,
      'user1Accepted': this.user1Accepted,
      'user2Accepted': this.user2Accepted,
      'u1P1Id': this.u1P1Id,
      'u1P1Name': this.u1P1Name,
      'u1P1Price': this.u1P1Price,
      'u2P1Id': this.u2P1Id,
      'u2P1Name': this.u2P1Name,
      'u2P1Price': this.u2P1Price,
      'proposedBy': this.proposedBy,
      'lastProposedDate': this.lastProposedDate,
      'dealStatus': this.dealStatus,
      'dealDate': this.dealDate,
      'u1P1Image': this.u1P1Image,
      'u2P1Image': this.u2P1Image,
      'barterId': this.barterId,
      'barterNo': this.barterNo,
      'userid1Role': this.userid1Role,
      'userid2Role': this.userid2Role,
      'userid1Name': this.userid1Name,
      'userid2Name': this.userid2Name,
      'deletedFor': this.deletedFor,
    };
  }
}
