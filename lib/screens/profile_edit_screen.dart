import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/pokemon.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/photo_encoder.dart';
import '../widgets/poke_background.dart';
import '../widgets/pokemon_image.dart';
import '../widgets/user_avatar.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final UserProfile _original;
  late final TextEditingController _name, _age, _city, _country, _bio;
  String? _photo;
  String? _thumb;
  String? _favorite;
  bool _saving = false;

  static const bioMaxLength = 200;

  @override
  void initState() {
    super.initState();
    _original = context.read<AuthService>().currentUser!;
    _name = TextEditingController(text: _original.name);
    _age = TextEditingController(text: _original.age?.toString() ?? '');
    _city = TextEditingController(text: _original.city ?? '');
    _country = TextEditingController(text: _original.country ?? '');
    _bio = TextEditingController(text: _original.bio ?? '');
    _photo = _original.photo;
    _thumb = _original.photoThumb;
    _favorite = _original.favoritePokemon;
  }

  @override
  void dispose() {
    for (final c in [_name, _age, _city, _country, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    Navigator.of(context).pop();
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (picked == null) return;
    final encoded = await encodeProfilePhoto(await picked.readAsBytes());
    if (!mounted) return;
    if (encoded == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível ler essa imagem.')),
      );
      return;
    }
    setState(() {
      _photo = encoded.photo;
      _thumb = encoded.thumb;
    });
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () => _pickPhoto(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tirar foto'),
              onTap: () => _pickPhoto(ImageSource.camera),
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remover foto'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _photo = _thumb = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final updated = _original.copyWith(
      name: _name.text.trim(),
      age: () => int.tryParse(_age.text.trim()),
      city: () => _nullIfEmpty(_city.text),
      country: () => _nullIfEmpty(_country.text),
      bio: () => _nullIfEmpty(_bio.text),
      favoritePokemon: () => _favorite,
      photo: () => _photo,
      photoThumb: () => _thumb,
    );
    try {
      await context.read<AuthService>().updateProfile(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Não foi possível salvar: $e')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final favorite = Pokemon.byName(_favorite);
    return PokeScaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            UserAvatar(
                              name: _name.text,
                              photo: _photo,
                              radius: 56,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IconButton.filled(
                                icon: const Icon(Icons.camera_alt),
                                onPressed: _showPhotoOptions,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(child: Text(_original.email)),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Informe seu nome'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Idade'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final n = int.tryParse(v.trim());
                          return (n == null || n < 1 || n > 120)
                              ? 'Idade inválida'
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _city,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Cidade'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _country,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'País'),
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<Pokemon>(
                        initialValue: TextEditingValue(text: _favorite ?? ''),
                        displayStringForOption: (p) => p.name,
                        optionsBuilder: (value) {
                          final q = value.text.trim().toLowerCase();
                          if (q.isEmpty) return const Iterable<Pokemon>.empty();
                          return Pokemon.all
                              .where(
                                (p) =>
                                    p.name.toLowerCase().contains(q) ||
                                    p.id.toString() == q,
                              )
                              .take(20);
                        },
                        onSelected: (p) => setState(() => _favorite = p.name),
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmit) =>
                                TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Pokémon preferido',
                                    hintText: 'Digite o nome ou o número',
                                    suffixIcon: _favorite == null
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              controller.clear();
                                              setState(() => _favorite = null);
                                            },
                                          ),
                                  ),
                                  validator: (v) =>
                                      (v == null ||
                                          v.trim().isEmpty ||
                                          Pokemon.byName(v.trim()) != null)
                                      ? null
                                      : 'Escolha um Pokémon da lista',
                                  onChanged: (v) {
                                    // Só aceita um nome da lista; texto livre limpa a escolha.
                                    final match = Pokemon.byName(v.trim());
                                    if (match?.name != _favorite) {
                                      setState(() => _favorite = match?.name);
                                    }
                                  },
                                ),
                      ),
                      if (favorite != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: PokemonImage(pokemon: favorite, size: 140),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bio,
                        maxLines: 4,
                        maxLength: bioMaxLength,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText:
                              'Conte um pouco sobre você como treinador...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
