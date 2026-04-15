import 'dart:async';

import 'package:flutter/material.dart';
import 'package:alto/models/relation_info.dart';
import 'package:alto/models/element_model.dart';
import 'package:alto/services/element_service.dart';

class RelationScreen extends StatefulWidget {
  final RelationInfo relation;
  const RelationScreen({super.key, required this.relation});

  @override
  State<RelationScreen> createState() => _RelationScreenState();
}

class _RelationScreenState extends State<RelationScreen> {
  final ElementService _elementService = ElementService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController    = ScrollController();

  final List<ElementModel> _messages    = [];
  ElementType _selectedType             = ElementType.message;
  Color       _selectedColor            = Colors.blue;
  String      _selectedEmoji            = '😊';

  bool    _isSending   = false;
  bool    _isReceiving = false;
  String? _error;

  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _receive(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    // Détermine le contenu selon le type sélectionné
    final String plaintext;
    switch (_selectedType) {
      case ElementType.color:
        plaintext = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
        break;
      case ElementType.icon:
        plaintext = _selectedEmoji;
        break;
      default:
        plaintext = _textController.text.trim();
        if (plaintext.isEmpty) return;
    }

    setState(() { _isSending = true; _error = null; });

    try {
      await _elementService.send(
        myRelationCode:      widget.relation.myRelationCode,
        partnerPublicKeyPem: widget.relation.partnerPublicKeyPem,
        type:                _selectedType,
        plaintext:           plaintext,
      );

      // Ajoute dans l'historique local (côté envoi)
      setState(() {
        _messages.add(ElementModel(
          key:            elementTypeToString(_selectedType),
          value:          '(chiffré)',
          decryptedValue: plaintext,
          isSentByMe:     true,
        ));
        _textController.clear();
      });
      _scrollToBottom();

    } catch (e) {
      setState(() { _error = 'Envoi échoué : $e'; });
    } finally {
      setState(() { _isSending = false; });
    }
  }


  Future<void> _receive() async {
    if (_isReceiving) return;
    setState(() { _isReceiving = true; _error = null; });

    try {
      final element = await _elementService.receive(
        partnerRelationCode: widget.relation.partnerRelationCode,
        myRelationCode:      widget.relation.myRelationCode,
      );

      if (element != null) {
        setState(() { _messages.add(element); });
        _scrollToBottom();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📩 Nouveau message reçu !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() { _error = 'Réception échouée : $e'; });
    } finally {
      setState(() { _isReceiving = false; });
    }
  }

  void _showColorPicker() {
    final colors = [
      Colors.red, Colors.orange, Colors.yellow, Colors.green,
      Colors.blue, Colors.purple, Colors.pink, Colors.teal,
      Colors.brown, Colors.grey, Colors.black, Colors.white,
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir une couleur'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((c) => GestureDetector(
            onTap: () { setState(() => _selectedColor = c); Navigator.pop(ctx); },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: _selectedColor == c
                    ? Border.all(color: Colors.black, width: 3)
                    : Border.all(color: Colors.grey.shade300),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  // Zone de saisie adaptée au type
  Widget _buildInput() {
    switch (_selectedType) {
      case ElementType.color:
        return GestureDetector(
          onTap: _showColorPicker,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}  — Appuyer pour changer',
                style: TextStyle(
                  color: _selectedColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );

      case ElementType.icon:
        const emojis = ['😊','😂','❤️','🎉','👍','🔥','✨','🎵','🌍','🚀','💡','🔐','😎','🤔','😴'];
        return Wrap(
          spacing: 6,
          children: emojis.map((e) => GestureDetector(
            onTap: () => setState(() => _selectedEmoji = e),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _selectedEmoji == e
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: _selectedEmoji == e
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
              ),
              child: Text(e, style: const TextStyle(fontSize: 22)),
            ),
          )).toList(),
        );

      default:
        // MESSAGE, URL, LOCATION → champ texte
        return TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: _selectedType == ElementType.url
                ? 'https://...'
                : _selectedType == ElementType.location
                    ? '48.8566,2.3522  (lat,lng)'
                    : 'Écrire un message...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: _selectedType == ElementType.message ? 3 : 1,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
        );
    }
  }

  // Bulle de message (s'adapte au type)
  Widget _buildBubble(ElementModel el) {
    final isMine = el.isSentByMe;
    final val    = el.decryptedValue ?? el.value;
    final type   = elementTypeFromString(el.key);

    Widget content;
    switch (type) {
      case ElementType.icon:
        content = Text(val, style: const TextStyle(fontSize: 42));
        break;

      case ElementType.color:
        final c = _parseColor(val);
        content = Container(
          width: 100,
          height: 50,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              val,
              style: TextStyle(
                color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        );
        break;

      case ElementType.url:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                val,
                style: TextStyle(
                  color: isMine ? Colors.white70 : Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
        break;

      case ElementType.location:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 18),
            const SizedBox(width: 4),
            Flexible(child: Text(val)),
          ],
        );
        break;

      default:
        content = Text(val, style: const TextStyle(fontSize: 15));
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  isMine ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMine ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: isMine
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
          child: content,
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerShort = widget.relation.partnerRelationCode.substring(0, 8);

    return Scaffold(
      appBar: AppBar(
        title: Text('Relation $partnerShort...'),
        actions: [
          // Bouton refresh manuel
          _isReceiving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Récupérer les messages',
                  onPressed: _receive,
                ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau d'erreur
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: const Text('OK'),
                ),
              ],
            ),

          // Historique des messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Aucun message'),
                        const SizedBox(height: 4),
                        Text(
                          'Envoyez un message ou appuyez sur ↻',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(_messages[i]),
                  ),
          ),

          // Zone de composition
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sélecteur de type
                DropdownButtonFormField<ElementType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: ElementType.message,  child: Text('💬 MESSAGE')),
                    DropdownMenuItem(value: ElementType.icon,     child: Text('😊 ICON')),
                    DropdownMenuItem(value: ElementType.color,    child: Text('🎨 COLOR')),
                    DropdownMenuItem(value: ElementType.url,      child: Text('🔗 URL')),
                    DropdownMenuItem(value: ElementType.location, child: Text('📍 LOCATION')),
                  ],
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: 8),

                // Saisie adaptée au type
                _buildInput(),
                const SizedBox(height: 8),

                // Bouton envoyer (style FilledButton comme Selyan)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Chiffrement...' : 'Envoyer 🔒'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}