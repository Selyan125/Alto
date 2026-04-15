import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStorage {
  static const _storage = FlutterSecureStorage();

  // Clés de stockage : "rel:<relationCode>:pub" / ":priv"
  static String _pub(String code)  => 'rel:$code:pub';
  static String _priv(String code) => 'rel:$code:priv';

  // Sauvegarde la paire après génération RSA
  static Future<void> saveKeyPair(
    String myRelationCode, {
    required String publicKeyPem,
    required String privateKeyPem,
  }) async {
    await _storage.write(key: _pub(myRelationCode),  value: publicKeyPem);
    await _storage.write(key: _priv(myRelationCode), value: privateKeyPem);
  }

  // Lit la clé publique (pour l'envoyer au partenaire)
  static Future<String?> readPublicKey(String myRelationCode) =>
      _storage.read(key: _pub(myRelationCode));

  // Lit la clé privée (pour déchiffrer les messages reçus)
  static Future<String?> readPrivateKey(String myRelationCode) =>
      _storage.read(key: _priv(myRelationCode));

  // Supprime les clés (si on efface une relation)
  static Future<void> deleteKeyPair(String myRelationCode) async {
    await _storage.delete(key: _pub(myRelationCode));
    await _storage.delete(key: _priv(myRelationCode));
  }
}