import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil do treinador, guardado em `users/{uid}` no Firestore.
class UserProfile {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? city;
  final String? country;
  final String? favoritePokemon;
  final String? bio;

  /// Foto em JPEG codificado em base64 (256px) e miniatura (64px) usada no
  /// ranking. Guardadas no próprio documento, sem precisar do Cloud Storage.
  final String? photo;
  final String? photoThumb;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.city,
    this.country,
    this.favoritePokemon,
    this.bio,
    this.photo,
    this.photoThumb,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return UserProfile(
      id: doc.id,
      email: d['email'] as String? ?? '',
      name: d['name'] as String? ?? 'Treinador',
      age: (d['age'] as num?)?.toInt(),
      city: d['city'] as String?,
      country: d['country'] as String?,
      favoritePokemon: d['favoritePokemon'] as String?,
      bio: d['bio'] as String?,
      photo: d['photo'] as String?,
      photoThumb: d['photoThumb'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
    'email': email,
    'name': name,
    'age': age,
    'city': city,
    'country': country,
    'favoritePokemon': favoritePokemon,
    'bio': bio,
    'photo': photo,
    'photoThumb': photoThumb,
  };

  UserProfile copyWith({
    String? name,
    int? Function()? age,
    String? Function()? city,
    String? Function()? country,
    String? Function()? favoritePokemon,
    String? Function()? bio,
    String? Function()? photo,
    String? Function()? photoThumb,
  }) => UserProfile(
    id: id,
    email: email,
    name: name ?? this.name,
    age: age != null ? age() : this.age,
    city: city != null ? city() : this.city,
    country: country != null ? country() : this.country,
    favoritePokemon: favoritePokemon != null
        ? favoritePokemon()
        : this.favoritePokemon,
    bio: bio != null ? bio() : this.bio,
    photo: photo != null ? photo() : this.photo,
    photoThumb: photoThumb != null ? photoThumb() : this.photoThumb,
  );
}
