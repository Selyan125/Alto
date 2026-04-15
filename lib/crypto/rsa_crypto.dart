import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/oaep.dart';


String rsaEncrypt({
  required String recipientPublicKeyPem,
  required String plaintext,
}) {
  final bytes = utf8.encode(plaintext);
  if (bytes.length > 214) {
    throw Exception(
      'Message trop long (${bytes.length} octets). '
      'RSA-2048 supporte max ~214 octets (~150 caractères).',
    );
  }

  final pubKey = CryptoUtils.rsaPublicKeyFromPem(recipientPublicKeyPem);
  final engine = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(pubKey));

  return base64Encode(engine.process(Uint8List.fromList(bytes)));
}

String rsaDecrypt({
  required String myPrivateKeyPem,
  required String ciphertextBase64,
}) {
  final privKey = CryptoUtils.rsaPrivateKeyFromPem(myPrivateKeyPem);
  final engine  = OAEPEncoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(privKey));

  return utf8.decode(engine.process(base64Decode(ciphertextBase64)));
}