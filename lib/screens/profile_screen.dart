import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pokemon.dart';
import '../services/auth_service.dart';
import '../widgets/pokemon_image.dart';
import '../widgets/user_avatar.dart';
import 'profile_edit_screen.dart';

/// Aba "Perfil": mostra os dados do treinador.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser!;
    final favorite = Pokemon.byName(user.favoritePokemon);
    final textTheme = Theme.of(context).textTheme;
    final place = [user.city, user.country].whereType<String>().join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                UserAvatar(name: user.name, photo: user.photo, radius: 56),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(user.email, style: textTheme.bodySmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (user.age != null)
                      Chip(
                        avatar: const Icon(Icons.cake, size: 18),
                        label: Text('${user.age} anos'),
                      ),
                    if (place.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.place, size: 18),
                        label: Text(place),
                      ),
                  ],
                ),
                if (user.bio != null) ...[
                  const SizedBox(height: 12),
                  Text(user.bio!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
        if (favorite != null)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: PokemonImage(pokemon: favorite, size: 64),
              title: const Text('Pokémon preferido'),
              subtitle: Text(
                '${favorite.name} ${favorite.dexNumber}',
                style: textTheme.titleMedium,
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Editar perfil'),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
          onPressed: auth.logout,
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Excluir minha conta'),
            onPressed: () => _confirmDelete(context),
          ),
        ),
        const _FanAppNotice(),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final password = TextEditingController();
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seu perfil e suas pontuações serão apagados para sempre. '
              'Digite sua senha para confirmar.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await auth.deleteAccount(password.text);
      messenger.showSnackBar(const SnackBar(content: Text('Conta excluída.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _FanAppNotice extends StatelessWidget {
  const _FanAppNotice();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 8),
    child: Text(
      'PokeQuiz é um app de fã, sem fins lucrativos e sem vínculo com '
      'Nintendo, Game Freak ou The Pokémon Company. Pokémon e os nomes '
      'dos personagens são marcas de seus respectivos donos.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white70, fontSize: 11),
    ),
  );
}
