import 'dart:convert';

import 'package:alto/models/pairing_session.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class PairingService {
  PairingService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://alto.samyn.ovh';
  static const Duration requestTimeout = Duration(seconds: 10);
  final http.Client _client;
  final Uuid _uuid = const Uuid();

  PairingSession startLocalSession() {
    final sessionId = _uuid.v4();
    final payload = jsonEncode({'pairingId': sessionId});

    return PairingSession(
      sessionId: sessionId,
      qrPayload: payload,
    );
  }

  String parsePairingId(String rawQrValue) {
    try {
      final dynamic decoded = jsonDecode(rawQrValue);
      if (decoded is Map<String, dynamic>) {
        final pairingId = decoded['pairingId']?.toString();
        if (pairingId != null && pairingId.isNotEmpty) {
          return pairingId;
        }
      }
    } catch (_) {
      // Fallback
    }

    if (rawQrValue.trim().isEmpty) {
      throw const FormatException('QR code vide.');
    }

    return rawQrValue.trim();
  }

  Future<void> sendPairingRequest(String pairingId) async {
    final uri = Uri.parse('$_baseUrl/pairing');

    final response = await _client
        .put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'pairingId': pairingId}),
        )
        .timeout(requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur lors du pairing: HTTP ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<bool> getPairingStatus(String pairingId) async {
    final uri = Uri.parse('$_baseUrl/pairing/status/$pairingId');
    final response = await _client.get(uri).timeout(requestTimeout);

    if (response.statusCode == 404) {
      return false;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur lors de la verification du statut: HTTP ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.trim().isEmpty) {
      return false;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final value = decoded['completed'] ?? decoded['isCompleted'] ?? decoded['done'];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      if (value is num) {
        return value == 1;
      }
    }

    return false;
  }

  Future<void> finalizePairing(String pairingId) async {
    final uri = Uri.parse('$_baseUrl/pairing/$pairingId');
    final response = await _client.delete(uri).timeout(requestTimeout);

    if (response.statusCode == 404) {
      return;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur: HTTP ${response.statusCode} ${response.body}',
      );
    }
  }
}
