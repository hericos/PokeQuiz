import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar que aceita URL remota (Google), arquivo local ou nenhuma foto.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.photo, this.radius = 24});

  final String name;
  final String? photo;
  final double radius;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (photo != null && photo!.isNotEmpty) {
      if (photo!.startsWith('http')) {
        image = CachedNetworkImageProvider(photo!);
      } else if (File(photo!).existsSync()) {
        image = FileImage(File(photo!));
      }
    }
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: image,
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(fontSize: radius * 0.8, color: scheme.onPrimaryContainer),
      ),
    );
  }
}
