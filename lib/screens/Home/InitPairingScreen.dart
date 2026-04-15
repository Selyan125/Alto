import 'dart:async';

import 'package:alto/crypto/key_generator.dart';
import 'package:alto/crypto/key_storage.dart';
import 'package:alto/models/pairing_session.dart';
import 'package:alto/models/relation_info.dart';
import 'package:alto/routes/app_routes.dart';
import 'package:alto/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class InitPairingScreen extends StatefulWidget {
  const InitPairingScreen({super.key});

  @override
  State<InitPairingScreen> createState() => _InitPairingScreenState();
}

class _InitPairingScreenState extends State<InitPairingScreen> {
  static const Duration _pollingInterval = Duration(seconds: 3);
  static const Duration _timeout         = Duration(minutes: 2);

  final ApiClient _api = ApiClient();
  final Uuid _uuid     = const Uuid();

  PairingSession? _session;   
  String?  _myPublicKeyPem;   
  Timer?   _pollingTimer;
  DateTime? _startedAt;

  bool _isLoadingKeys = false; 
  bool _isCompleted   = false;
  String? _statusMessage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startPairing();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPairing() async {
    setState(() {
      _isLoadingKeys  = true;
      _isCompleted    = false;
      _error          = null;
      _statusMessage  = 'Génération des clés RSA...';
      _session        = null;
    });

    try {
      // 1. Génère la paire RSA 
      final keyPair = generateRsaKeyPair();
      _myPublicKeyPem = keyPair.publicKeyPem;

      // 2. Génère mon relationCode (UUID)
      final myCode = _uuid.v4();

      // 3. Stocke la clé privée en sécurisé
      await KeyStorage.saveKeyPair(
        myCode,
        publicKeyPem:  keyPair.publicKeyPem,
        privateKeyPem: keyPair.privateKeyPem,
      );

      // 4. Envoie au serveur (POST /pairing)
      setState(() { _statusMessage = 'Enregistrement sur le serveur...'; });
      await _api.postPairing(
        relationCode:  myCode,
        userPublicKey: keyPair.publicKeyPem,
      );

      // 5. Crée la session locale pour afficher le QR
      final session = PairingSession(
        sessionId:  myCode,
        qrPayload:  myCode, // on encode directement le code dans le QR
      );

      setState(() {
        _session       = session;
        _isLoadingKeys = false;
        _startedAt     = DateTime.now();
        _statusMessage = 'En attente du scan...';
      });

      // 6. Démarre le polling du statut
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(_pollingInterval, (_) => _pollStatus());

    } catch (e) {
      setState(() {
        _isLoadingKeys = false;
        _error         = 'Erreur au démarrage : $e';
      });
    }
  }


  Future<void> _pollStatus() async {
    final session = _session;
    if (session == null || _isCompleted) return;

    // Timeout après 2 minutes
    if (_startedAt != null &&
        DateTime.now().difference(_startedAt!) > _timeout) {
      _pollingTimer?.cancel();
      if (mounted) setState(() { _error = 'QR code expiré. Veuillez régénérer.'; });
      return;
    }

    try {
      final status = await _api.getPairingStatus(session.sessionId);

      if (!mounted) return;

      if (status == 'completed') {
        // Bob a scanné → on finalise pour récupérer ses infos
        setState(() { _statusMessage = 'Connexion détectée ! Finalisation...'; });
        _pollingTimer?.cancel();
        await _finalize(session.sessionId);

      } else if (status == 'finalized') {
        // Cas où on arrive après la finalisation (ne devrait pas arriver ici)
        _pollingTimer?.cancel();
      }
      // "waiting" → on continue de poller

    } catch (e) {
      if (mounted) setState(() { _error = 'Erreur polling : $e'; });
    }
  }


  Future<void> _finalize(String myCode) async {
    try {
      final bobData = await _api.deletePairing(myCode);
      // bobData contient : { relationCodeB, publicKeyB }
      final bobCode   = bobData['relationCodeB'] as String? ?? '';
      final bobPubKey = bobData['publicKeyB']    as String? ?? '';

      if (!mounted) return;

      setState(() { _isCompleted = true; _statusMessage = 'Connexion établie ! 🎉'; });

      // Construit l'objet RelationInfo et navigue
      final relation = RelationInfo(
        myRelationCode:      myCode,
        partnerRelationCode: bobCode,
        myPublicKeyPem:      _myPublicKeyPem!,
        partnerPublicKeyPem: bobPubKey,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.relation,
          arguments: relation,
        );
      }

    } catch (e) {
      if (mounted) setState(() { _error = 'Erreur finalisation : $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return Scaffold(
      appBar: AppBar(title: const Text('Initialiser le pairing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoadingKeys
              // Pendant la génération RSA : spinner + message
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage ?? 'Chargement...',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // QR code
                    if (session != null) ...[
                      QrImageView(data: session.qrPayload, size: 240),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isCompleted ? Colors.green : null,
                          fontWeight: _isCompleted ? FontWeight.bold : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${session.sessionId.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],

                    // Erreur éventuelle
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Bouton régénérer (seulement si pas en cours)
                    if (!_isLoadingKeys && !_isCompleted)
                      FilledButton(
                        onPressed: _startPairing,
                        child: const Text('Regénérer le QR code'),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}