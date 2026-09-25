import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/pokemon.dart';

enum PokemonImageMode { full, partial, shadow }

/// Exibe a arte do Pokémon inteira, recortada (25% da área) ou como sombra.
class PokemonImage extends StatelessWidget {
  const PokemonImage({
    super.key,
    required this.pokemon,
    this.mode = PokemonImageMode.full,
    this.cropX = 0,
    this.cropY = 0,
    this.size = 260,
  });

  final Pokemon pokemon;
  final PokemonImageMode mode;
  final double cropX;
  final double cropY;
  final double size;

  /// Zera RGB e mantém o alpha: vira uma silhueta preta.
  static const _shadowMatrix = <double>[
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: pokemon.imageUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (_, _) => SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: const Center(child: Icon(Icons.wifi_off, size: 48)),
      ),
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
        // Janela com metade da largura e metade da altura = 25% da imagem,
        // ampliada para ocupar o mesmo espaço.
        return SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: BoxFit.contain,
            child: ClipRect(
              child: Align(
                alignment: Alignment(cropX, cropY),
                widthFactor: 0.5,
                heightFactor: 0.5,
                child: image,
              ),
            ),
          ),
        );
    }
  }
}
