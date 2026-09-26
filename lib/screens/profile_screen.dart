import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pokemon.dart';
import '../models/user_profile.dart';
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
                    Chip(
                      avatar: Icon(
                        user.provider == AuthProvider.google
                            ? Icons.g_mobiledata
                            : Icons.lock,
                        size: 18,
                      ),
                      label: Text(
                        user.provider == AuthProvider.google
                            ? 'Conta Google'
                            : 'Conta local',
                      ),
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
      ],
    );
  }
}
