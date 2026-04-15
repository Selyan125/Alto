import '../crypto/key_storage.dart';
import '../crypto/rsa_crypto.dart';
import '../models/element_model.dart';
import 'api_client.dart';

class ElementService {
  final ApiClient _api;
  ElementService({ApiClient? api}) : _api = api ?? ApiClient();
  
  Future<void> send({
    required String myRelationCode,
    required String partnerPublicKeyPem,
    required ElementType type,
    required String plaintext,
  }) async {
    // Chiffre avec la clé publique du destinataire
    final encrypted = rsaEncrypt(
      recipientPublicKeyPem: partnerPublicKeyPem,
      plaintext: plaintext,
    );

    await _api.postElement(
      relationCode: myRelationCode,
      key:          elementTypeToString(type),
      value:        encrypted,
    );
  }


  Future<ElementModel?> receive({
    required String partnerRelationCode,
    required String myRelationCode,
  }) async {
    final data = await _api.getElement(partnerRelationCode);
    if (data == null) return null;

    final element = ElementModel.fromJson(data);

    // Récupère notre clé privée depuis le stockage sécurisé
    final privKey = await KeyStorage.readPrivateKey(myRelationCode);
    if (privKey == null) {
      throw Exception('Clé privée introuvable pour la relation $myRelationCode');
    }

    final plaintext = rsaDecrypt(
      myPrivateKeyPem:    privKey,
      ciphertextBase64:   element.value,
    );

    return element.withDecrypted(plaintext);
  }
}