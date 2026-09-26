import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Avatar com a foto do perfil (JPEG em base64) ou a inicial do nome.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photo,
    this.radius = 24,
  });

  final String name;
  final String? photo;
  final double radius;

  static final _cache = <String, Uint8List>{};

  static Uint8List? _decode(String? data) {
    if (data == null || data.isEmpty) return null;
    if (_cache.length > 200) _cache.clear();
    try {
      return _cache.putIfAbsent(data, () => base64Decode(data));
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(photo);
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: bytes == null ? null : MemoryImage(bytes),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.8,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
