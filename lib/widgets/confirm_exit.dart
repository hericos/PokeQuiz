import 'package:flutter/material.dart';

/// Envolve a tela de um jogo pedindo confirmação antes de sair no meio.
class ConfirmExit extends StatelessWidget {
  const ConfirmExit({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !enabled,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sair do jogo?'),
            content: const Text('O progresso desta partida será perdido.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if (leave ?? false) navigator.pop();
      },
      child: child,
    );
  }
}
