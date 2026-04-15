import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/random/fortuna_random.dart';

// Résultat retourné par generateRsaKeyPair()
typedef RsaKeyPair = ({String publicKeyPem, String privateKeyPem});

// Construit un générateur aléatoire cryptographiquement sûr
FortunaRandom _buildSecureRandom() {
  final rng  = FortunaRandom();
  final seed = Uint8List(32);
  final r    = Random.secure();
  for (var i = 0; i < seed.length; i++) seed[i] = r.nextInt(256);
  rng.seed(KeyParameter(seed));
  return rng;
}


RsaKeyPair generateRsaKeyPair() {
  final gen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
      _buildSecureRandom(),
    ));

  final pair       = gen.generateKeyPair();
  final publicKey  = pair.publicKey  as RSAPublicKey;
  final privateKey = pair.privateKey as RSAPrivateKey;

  return (
    publicKeyPem:  CryptoUtils.encodeRSAPublicKeyToPem(publicKey),
    privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
  );
}