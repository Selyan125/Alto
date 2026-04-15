
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _base = 'https://alto.samyn.ovh';
  static const Duration _timeout = Duration(seconds: 10);
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  final http.Client _client;
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<void> postPairing({
    required String relationCode,
    required String userPublicKey,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/pairing'),
      headers: _headers,
      body: jsonEncode({'relationCode': relationCode, 'userPublicKey': userPublicKey}),
    ).timeout(_timeout);
    _check(res);
  }


  Future<Map<String, dynamic>> putPairing({
    required String relationCodeA,
    required String relationCodeB,
    required String publicKeyB,
  }) async {
    final res = await _client.put(
      Uri.parse('$_base/pairing'),
      headers: _headers,
      body: jsonEncode({
        'relationCodeA': relationCodeA,
        'relationCodeB': relationCodeB,
        'publicKeyB':    publicKeyB,
      }),
    ).timeout(_timeout);
    return _check(res);
  }

 
  Future<String> getPairingStatus(String relationCode) async {
    final res = await _client
        .get(Uri.parse('$_base/pairing/$relationCode/status'), headers: _headers)
        .timeout(_timeout);
    final body = _check(res);
    return (body['status'] as String?) ?? '';
  }

  // DELETE /pairing?relationCodeA=xxx
  // Alice finalise et récupère les infos de Bob.

  Future<Map<String, dynamic>> deletePairing(String relationCodeA) async {
    final res = await _client
        .delete(Uri.parse('$_base/pairing?relationCodeA=$relationCodeA'), headers: _headers)
        .timeout(_timeout);
    return _check(res);
  }

  // POST /element
  // Dépose un message chiffré pour le destinataire.
  Future<void> postElement({
    required String relationCode,
    required String key,
    required String value,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/element'),
      headers: _headers,
      body: jsonEncode({'relationCode': relationCode, 'key': key, 'value': value}),
    ).timeout(_timeout);
    _check(res);
  }

  // GET /element?relationCode=xxx
  // Récupère le message en attente (READ-ONCE).

  Future<Map<String, dynamic>?> getElement(String relationCode) async {
    final res = await _client
        .get(Uri.parse('$_base/element?relationCode=$relationCode'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode == 404) return null;
    return _check(res);
  }

  // Vérifie le statut HTTP et parse le JSON
  Map<String, dynamic> _check(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.trim().isEmpty) return {};
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('API ${res.statusCode}: ${res.body}');
  }
}