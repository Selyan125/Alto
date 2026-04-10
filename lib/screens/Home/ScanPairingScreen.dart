import 'package:alto/services/pairing_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPairingScreen extends StatefulWidget {
	const ScanPairingScreen({super.key});

	@override
	State<ScanPairingScreen> createState() => _ScanPairingScreenState();
}

class _ScanPairingScreenState extends State<ScanPairingScreen> {
	final PairingService _pairingService = PairingService();
	final MobileScannerController _scannerController = MobileScannerController();

	bool _isSyncing = false;
	String? _message;
	bool _success = false;

	Future<void> _handleScan(BarcodeCapture capture) async {
		if (_isSyncing) {
			return;
		}

		final rawValue =
				capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
		if (rawValue == null || rawValue.trim().isEmpty) {
			setState(() {
				_message = 'QR code invalide.';
				_success = false;
			});
			return;
		}

		setState(() {
			_isSyncing = true;
			_message = 'Synchronisation en cours...';
			_success = false;
		});

		try {
			final pairingId = _pairingService.parsePairingId(rawValue);
			await _pairingService.sendPairingRequest(pairingId);

			setState(() {
				_message = 'Connexion établie.';
				_success = true;
			});
			await _scannerController.stop();
		} catch (e) {
			setState(() {
				_message = 'Échec du pairing: $e';
				_success = false;
			});
			await _scannerController.start();
		} finally {
			if (mounted) {
				setState(() {
					_isSyncing = false;
				});
			}
		}
	}

	@override
	void dispose() {
		_scannerController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Scanner le QR code'),
			),
			body: Column(
				children: [
					Expanded(
						child: MobileScanner(
							controller: _scannerController,
							onDetect: _handleScan,
						),
					),
					Padding(
						padding: const EdgeInsets.all(16),
						child: Row(
							children: [
								Icon(
									_success ? Icons.check_circle : Icons.info,
									color: _success
											? Colors.green
											: Theme.of(context).colorScheme.primary,
								),
								const SizedBox(width: 12),
								Expanded(
									child: Text(
										_message ?? 'Scannez un QR Code pour lancer une tentative de connexion',
									),
								),
							],
						),
					),
					if (_success)
						Padding(
							padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
							child: FilledButton(
								onPressed: () => Navigator.pop(context),
								child: const Text('Retour à l\'accueil'),
							),
						),
				],
			),
		);
	}
}
