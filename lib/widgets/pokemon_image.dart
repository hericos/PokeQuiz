import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';

import '../models/pokemon.dart';

enum PokemonImageMode { full, partial, shadow }

/// Na web, baixa a imagem por HTTP em vez de usar o <img> do navegador
/// (padrão do cached_network_image): com o <img>, imagens pré-carregadas
/// ficavam pretas ao aparecer dentro de animações (AnimatedSwitcher).
const _webRenderMethod = ImageRenderMethodForWeb.HttpGet;

/// Provider das artes, para pré-carregar com as mesmas opções do widget.
ImageProvider pokemonImageProvider(String url) =>
    CachedNetworkImageProvider(url, imageRenderMethodForWeb: _webRenderMethod);

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
    Widget image = CachedNetworkImage(
      imageRenderMethodForWeb: _webRenderMethod,
      imageUrl: shiny ? pokemon.shinyImageUrl : pokemon.imageUrl,
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
