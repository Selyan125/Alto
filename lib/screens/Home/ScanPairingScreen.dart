import 'dart:async';

import 'package:alto/crypto/key_generator.dart';
import 'package:alto/crypto/key_storage.dart';
import 'package:alto/models/relation_info.dart';
import 'package:alto/routes/app_routes.dart';
import 'package:alto/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

class ScanPairingScreen extends StatefulWidget {
  const ScanPairingScreen({super.key});

  @override
  State<ScanPairingScreen> createState() => _ScanPairingScreenState();
}

class _ScanPairingScreenState extends State<ScanPairingScreen> {
  static const Duration _pollingInterval = Duration(seconds: 3);
  static const Duration _timeout         = Duration(minutes: 2);

  final ApiClient _api                     = ApiClient();
  final MobileScannerController _scanner   = MobileScannerController();
  final Uuid _uuid                         = const Uuid();

  bool    _isSyncing   = false;
  bool    _isPolling   = false;
  bool    _success     = false;
  String? _message;
  String? _myCode;      
  String? _aliceCode;   
  Timer?  _pollingTimer;
  DateTime? _startedAt;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scanner.dispose();
    super.dispose();
  }


  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isSyncing || _isPolling || _success) return;

    final rawValue = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (rawValue == null || rawValue.trim().isEmpty) {
      setState(() { _message = 'QR code invalide.'; });
      return;
    }

    setState(() {
      _isSyncing = true;
      _message   = 'Génération des clés RSA...';
    });

    try {
      final aliceCode = rawValue.trim();
      _aliceCode = aliceCode;

      final keyPair = generateRsaKeyPair();
      final myCode  = _uuid.v4();
      _myCode = myCode;

      await KeyStorage.saveKeyPair(
        myCode,
        publicKeyPem:  keyPair.publicKeyPem,
        privateKeyPem: keyPair.privateKeyPem,
      );

      setState(() { _message = 'Connexion au serveur...'; });

      final aliceData = await _api.putPairing(
        relationCodeA: aliceCode,
        relationCodeB: myCode,
        publicKeyB:    keyPair.publicKeyPem,
      );

      final alicePubKey = aliceData['publicKeyA'] as String? ?? '';

      await _scanner.stop();
      setState(() {
        _isSyncing  = false;
        _isPolling  = true;
        _message    = 'Scan réussi ! En attente de la confirmation d\'Alice...';
        _startedAt  = DateTime.now();
      });

      // Sauvegarde les infos d'Alice pour les utiliser à la fin
      _pendingRelation = RelationInfo(
        myRelationCode:      myCode,
        partnerRelationCode: aliceCode,
        myPublicKeyPem:      keyPair.publicKeyPem,
        partnerPublicKeyPem: alicePubKey,
      );

      _pollingTimer = Timer.periodic(
        _pollingInterval, (_) => _pollForFinalized(aliceCode),
      );

    } catch (e) {
      setState(() {
        _message   = 'Échec : $e';
        _isSyncing = false;
      });
      await _scanner.start();
    }
  }

  // Stocke la relation en attente de "finalized"
  RelationInfo? _pendingRelation;


  Future<void> _pollForFinalized(String aliceCode) async {
    if (!_isPolling || _success) return;

    if (_startedAt != null &&
        DateTime.now().difference(_startedAt!) > _timeout) {
      _pollingTimer?.cancel();
      if (mounted) setState(() { _message = 'Timeout. Veuillez réessayer.'; _isPolling = false; });
      return;
    }

    try {
      final status = await _api.getPairingStatus(aliceCode);

      if (!mounted) return;

      if (status == 'finalized') {
        _pollingTimer?.cancel();
        setState(() {
          _success   = true;
          _isPolling = false;
          _message   = 'Connexion établie ! 🎉';
        });

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted && _pendingRelation != null) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.relation,
            arguments: _pendingRelation,
          );
        }
      }

    } catch (e) {
      if (mounted) setState(() { _message = 'Erreur polling : $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner le QR code')),
      body: Column(
        children: [
          if (!_isPolling && !_success)
            Expanded(
              child: MobileScanner(
                controller: _scanner,
                onDetect: _handleScan,
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_success)
                      const CircularProgressIndicator()
                    else
                      const Icon(Icons.check_circle, color: Colors.green, size: 80),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _success       ? Icons.check_circle
                  : _isSyncing || _isPolling ? Icons.sync
                  : Icons.info,
                  color: _success ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _message ??
                        'Scannez le QR code affiché par votre contact.',
                  ),
                ),
              ],
            ),
          ),

          if (_success || (_message != null && !_isSyncing && !_isPolling))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Retour à l'accueil"),
              ),
            ),
        ],
      ),
    );
  }
}