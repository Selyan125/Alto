

import 'dart:convert';

class RelationInfo {
  final String myRelationCode;
  final String partnerRelationCode;
  final String myPublicKeyPem;
  final String partnerPublicKeyPem;

  RelationInfo({
    required this.myRelationCode,
    required this.partnerRelationCode,
    required this.myPublicKeyPem,
    required this.partnerPublicKeyPem,
  });

  // Sérialise en JSON (pour stockage local éventuel)
  Map<String, dynamic> toJson() => {
    'myRelationCode':      myRelationCode,
    'partnerRelationCode': partnerRelationCode,
    'myPublicKeyPem':      myPublicKeyPem,
    'partnerPublicKeyPem': partnerPublicKeyPem,
  };

  factory RelationInfo.fromJson(Map<String, dynamic> json) => RelationInfo(
    myRelationCode:      json['myRelationCode'],
    partnerRelationCode: json['partnerRelationCode'],
    myPublicKeyPem:      json['myPublicKeyPem'],
    partnerPublicKeyPem: json['partnerPublicKeyPem'],
  );

  // Encode en String JSON (pratique pour passer en argument de route)
  String toJsonString() => jsonEncode(toJson());
  factory RelationInfo.fromJsonString(String s) =>
      RelationInfo.fromJson(jsonDecode(s));
}