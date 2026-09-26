import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Foto do perfil pronta para ir ao Firestore (JPEG em base64).
typedef EncodedPhoto = ({String photo, String thumb});

/// Recorta a imagem em quadrado e gera a foto (256px, ~20 KB) e a miniatura
/// do ranking (64px, ~2 KB). Roda fora da thread de UI.
Future<EncodedPhoto?> encodeProfilePhoto(Uint8List bytes) =>
    compute(_encode, bytes);

EncodedPhoto? _encode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final oriented = img.bakeOrientation(decoded);
  final side = oriented.width < oriented.height
      ? oriented.width
      : oriented.height;
  final square = img.copyCrop(
    oriented,
    x: (oriented.width - side) ~/ 2,
    y: (oriented.height - side) ~/ 2,
    width: side,
    height: side,
  );
  String jpeg(int size, int quality) => base64Encode(
    img.encodeJpg(
      img.copyResize(
        square,
        width: size,
        height: size,
        interpolation: img.Interpolation.average,
      ),
      quality: quality,
    ),
  );
  return (photo: jpeg(256, 75), thumb: jpeg(64, 70));
}
