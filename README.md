# PokeQuiz

Quiz de Pokémon feito em **Flutter** (Android agora, iOS no futuro).

## Funcionalidades

- **Login local** (e-mail + senha, guardados no aparelho com hash SHA-256 + salt) e **login com Google**.
- **Perfil**: foto (galeria ou câmera), nome, idade, cidade, país, Pokémon preferido e uma pequena bio.
- **Quem é esse Pokémon?** — 151 Pokémon de Kanto, 10 aleatórios por level:

| Level | Como é mostrado | Resposta | Pontos por acerto |
|---|---|---|---|
| 1 | Pokémon inteiro | 3 opções | 10 |
| 2 | Pedaço com 25% da imagem | 3 opções | 20 |
| 3 | Só a sombra | 4 opções | 30 |
| 4 | Só a sombra | Digitar o nome | 50 |

  Rodadas rápidas ganham até +50% de bônus de velocidade. Na resposta digitada,
  maiúsculas, acentos, espaços e pontuação são ignorados (`mr mime` = `Mr. Mime`).
- **Ranking**: ao fim de cada level você vê sua posição. Há ranking por level e
  geral (soma dos recordes de cada level), com títulos de *Treinador Iniciante* a *Mestre Pokémon*.

As imagens vêm do repositório [PokeAPI/sprites](https://github.com/PokeAPI/sprites)
(arte oficial) e ficam em cache no aparelho.

## Estrutura

```
lib/
  main.dart                 # bootstrap, providers e roteamento login/home
  theme.dart
  data/kanto_pokemon.dart   # os 151 nomes
  models/                   # Pokemon, UserProfile, QuizLevel/Question/Result
  services/
    database_service.dart   # SQLite (usuários e pontuações)
    auth_service.dart       # login local + Google, sessão
    quiz_engine.dart        # sorteio das rodadas e validação da resposta digitada
  screens/                  # login, home, quiz, resultado, ranking, perfil
  widgets/                  # PokemonImage (inteiro/recorte/sombra), UserAvatar
test/                       # testes unitários
```

## Rodando

```bash
flutter pub get
flutter test
flutter run                 # com um emulador/aparelho Android conectado
```

## Login com Google (Android)

O login com Google precisa de um projeto no Google Cloud (não precisa de Firebase):

1. Em **APIs e serviços → Credenciais**, crie um *OAuth client ID* do tipo **Android**
   com o pacote `com.hericos.pokequiz` e o SHA-1 da sua chave
   (`cd android && ./gradlew signingReport`).
2. Crie também um *OAuth client ID* do tipo **Web application**. O ID dele é o
   `serverClientId` exigido pelo Credential Manager do Android.
3. Rode/compile informando o ID Web:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
```

No GitHub Actions, cadastre o secret `GOOGLE_SERVER_CLIENT_ID`.

## Build de release para Android

1. Gere uma chave: `keytool -genkey -v -keystore ~/pokequiz.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pokequiz`
2. Crie `android/key.properties` (já está no `.gitignore`):

```properties
storePassword=...
keyPassword=...
keyAlias=pokequiz
storeFile=/caminho/para/pokequiz.jks
```

3. `flutter build appbundle` (Play Store) ou `flutter build apk` (instalação direta).

Sem `key.properties`, o release é assinado com a chave de debug (bom para testes).
O workflow `.github/workflows/android.yml` roda análise, testes e gera o APK
como artefato a cada push.

## iOS (futuro)

O projeto já inclui a pasta `ios/` e as permissões de câmera/galeria no `Info.plist`.
Para o Google no iOS, será preciso adicionar o `GIDClientID` e o URL scheme
conforme o [README do google_sign_in_ios](https://pub.dev/packages/google_sign_in_ios#ios-integration).
