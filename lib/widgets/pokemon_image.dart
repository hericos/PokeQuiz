import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/pokemon.dart';

enum PokemonImageMode { full, partial, shadow }

/// Provider das artes, usado também no pré-carregamento.
///
/// Na web usa o NetworkImage do próprio Flutter (o navegador já faz cache
/// HTTP): com o cached_network_image, imagens pré-carregadas ficavam pretas
/// no Chrome e em navegadores sem a API ImageDecoder (Safari/iOS).
/// No app, mantém o cache em disco do cached_network_image.
ImageProvider pokemonImageProvider(String url) =>
    kIsWeb ? NetworkImage(url) : CachedNetworkImageProvider(url);

/// Exibe a arte do Pokémon inteira, recortada (15% da área) ou como sombra.
class PokemonImage extends StatelessWidget {
  const PokemonImage({
    super.key,
    required this.pokemon,
    this.mode = PokemonImageMode.full,
    this.cropX = 0,
    this.cropY = 0,
    this.size = 260,
    this.shiny = false,
  });

  final Pokemon pokemon;
  final PokemonImageMode mode;
  final double cropX;
  final double cropY;
  final double size;

  /// Usa a arte da forma shiny (brilhante).
  final bool shiny;

  /// Lado da janela de recorte: sqrt(0.15) ≈ 0.387 → 15% da área.
  static final cropFactor = sqrt(0.15);

  /// Zera RGB e mantém o alpha: vira uma silhueta preta.
  static const _shadowMatrix = <double>[
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    Widget placeholder(Widget child) => SizedBox(
      width: size,
      height: size,
      child: Center(child: child),
    );
    Widget image = Image(
      image: pokemonImageProvider(
        shiny ? pokemon.shinyImageUrl : pokemon.imageUrl,
      ),
      width: size,
      height: size,
      fit: BoxFit.contain,
      frameBuilder: (_, child, frame, wasSyncLoaded) =>
          wasSyncLoaded || frame != null
          ? child
          : placeholder(const CircularProgressIndicator()),
      errorBuilder: (_, _, _) =>
          placeholder(const Icon(Icons.wifi_off, size: 48)),
    );

    switch (mode) {
      case PokemonImageMode.full:
        return image;
      case PokemonImageMode.shadow:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(_shadowMatrix),
          child: image,
        );
      case PokemonImageMode.partial:
        // Janela quadrada com 15% da área da imagem, ampliada para ocupar o
        // mesmo espaço.
        return SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: BoxFit.contain,
            child: ClipRect(
              child: Align(
                alignment: Alignment(cropX, cropY),
                widthFactor: cropFactor,
                heightFactor: cropFactor,
                child: image,
              ),
            ),
          ),
        );
    }
  }
}
