enum AuthProvider { local, google }

class UserProfile {
  final int id;
  final String email;
  final AuthProvider provider;
  final String name;
  final int? age;
  final String? city;
  final String? country;
  final String? favoritePokemon;
  final String? bio;

  /// Caminho local de uma foto escolhida pelo usuário ou URL (foto do Google).
  final String? photo;

  const UserProfile({
    required this.id,
    required this.email,
    required this.provider,
    required this.name,
    this.age,
    this.city,
    this.country,
    this.favoritePokemon,
    this.bio,
    this.photo,
  });

  bool get photoIsRemote => photo != null && photo!.startsWith('http');

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
        id: map['id'] as int,
        email: map['email'] as String,
        provider: AuthProvider.values.byName(map['provider'] as String),
        name: map['name'] as String,
        age: map['age'] as int?,
        city: map['city'] as String?,
        country: map['country'] as String?,
        favoritePokemon: map['favorite_pokemon'] as String?,
        bio: map['bio'] as String?,
        photo: map['photo'] as String?,
      );

  /// Somente os campos editáveis pelo usuário.
  Map<String, Object?> toProfileMap() => {
        'name': name,
        'age': age,
        'city': city,
        'country': country,
        'favorite_pokemon': favoritePokemon,
        'bio': bio,
        'photo': photo,
      };

  UserProfile copyWith({
    String? name,
    int? Function()? age,
    String? Function()? city,
    String? Function()? country,
    String? Function()? favoritePokemon,
    String? Function()? bio,
    String? Function()? photo,
  }) =>
      UserProfile(
        id: id,
        email: email,
        provider: provider,
        name: name ?? this.name,
        age: age != null ? age() : this.age,
        city: city != null ? city() : this.city,
        country: country != null ? country() : this.country,
        favoritePokemon:
            favoritePokemon != null ? favoritePokemon() : this.favoritePokemon,
        bio: bio != null ? bio() : this.bio,
        photo: photo != null ? photo() : this.photo,
      );
}
