import 'dart:async';

import 'package:alto/models/pairing_session.dart';
import 'package:alto/services/pairing_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InitPairingScreen extends StatefulWidget {
	const InitPairingScreen({super.key});

	@override
	State<InitPairingScreen> createState() => _InitPairingScreenState();
}

class _InitPairingScreenState extends State<InitPairingScreen> {
	static const Duration _pollingInterval = Duration(seconds: 3);
	static const Duration _timeout = Duration(minutes: 2);

	final PairingService _pairingService = PairingService();

	PairingSession? _session;
	Timer? _pollingTimer;
	DateTime? _startedAt;
	bool _isCompleted = false;
	bool _isLoading = true;
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
			_isLoading = true;
			_error = null;
		});

		final session = _pairingService.startLocalSession();

		setState(() {
			_session = session;
			_isLoading = false;
			_startedAt = DateTime.now();
		});

		_pollingTimer?.cancel();
		_pollingTimer = Timer.periodic(_pollingInterval, (_) => _pollStatus());
	}

	Future<void> _pollStatus() async {
		final session = _session;
		if (session == null || _isCompleted) {
			return;
		}

		final startedAt = _startedAt;
		if (startedAt != null && DateTime.now().difference(startedAt) > _timeout) {
			_pollingTimer?.cancel();
			if (!mounted) {
				return;
			}
			setState(() {
				_error = 'Delai depasse. Le QR code a expire.';
			});
			return;
		}

		try {
			final completed = await _pairingService.getPairingStatus(session.sessionId);
			if (!mounted || !completed) {
				return;
			}

			await _pairingService.finalizePairing(session.sessionId);
			_pollingTimer?.cancel();

			setState(() {
				_isCompleted = true;
			});
		} catch (e) {
			if (!mounted) {
				return;
			}

			setState(() {
				_error = 'Erreur de polling: $e';
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		final session = _session;

		return Scaffold(
			appBar: AppBar(
				title: const Text('Initialiser le pairing'),
			),
			body: Center(
				child: Padding(
					padding: const EdgeInsets.all(24),
					child: _isLoading
							? const CircularProgressIndicator()
							: Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										if (session != null) ...[
											QrImageView(
												data: session.qrPayload,
												size: 240,
											),
											const SizedBox(height: 16),
											Text(
												_isCompleted
														? 'Connexion etablie avec succes.'
														: 'Demandez a l\'autre utilisateur de scanner ce QR code.',
												textAlign: TextAlign.center,
											),
											const SizedBox(height: 12),
											Text(
												'ID: ${session.sessionId}',
												textAlign: TextAlign.center,
												style: Theme.of(context).textTheme.bodySmall,
											),
										],
										if (_error != null) ...[
											const SizedBox(height: 16),
											Text(
												_error!,
												style: TextStyle(color: Theme.of(context).colorScheme.error),
												textAlign: TextAlign.center,
											),
										],
										const SizedBox(height: 20),
										FilledButton(
											onPressed: _startPairing,
											child: const Text('Regenerer le QR code'),
										),
									],
								),
				),
			),
		);
	}
}
