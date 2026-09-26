# PokeQuiz

Quiz de Pokémon feito em **Flutter** (Android agora, iOS no futuro).

## Funcionalidades

- **Login local** (e-mail + senha, guardados no aparelho com hash SHA-256 + salt) e **login com Google**.
- **Perfil**: foto (galeria ou câmera), nome, idade, cidade, país, Pokémon preferido (busca por nome ou número) e bio.
- **Todos os 1025 Pokémon** da Pokédex Nacional (Kanto até Paldea).
- Navegação em 3 abas: **Jogos**, **Ranking** e **Perfil**. Cada jogo é um card no catálogo.

### Jogos

**Quem é esse Pokémon?** — uma partida única de 40 Pokémon. A cada 10 respondidos, sobe de level:

| Level | Como é mostrado | Resposta | Pontos por acerto |
|---|---|---|---|
| 1 | Pokémon inteiro | 3 opções | 10 |
| 2 | Pedaço com 15% da imagem | 3 opções | 20 |
| 3 | Só a sombra | 4 opções | 30 |
| 4 | Só a sombra | Digitar o nome | 50 |

Respostas em menos de 5s ganham até +50%. Na resposta digitada, maiúsculas,
acentos, espaços e pontuação são ignorados (`mr mime` = `Mr. Mime`).

**Forca** — sorteia um Pokémon e você escolhe letras. São 5 erros permitidos; a cada
erro uma parte do **Banette** aparece na forca. Cada Pokémon descoberto vale
10 + 5 por chance sobrando, e a partida segue até o Banette ficar completo.
A dica mostra a região do Pokémon.

### Ranking

Ao fim de cada partida aparece sua posição. Há ranking por jogo (melhor partida)
e geral (soma dos recordes), com títulos de *Treinador Iniciante* a *Mestre Pokémon*.

### Adicionando um jogo novo

1. Inclua um valor em `GameId` (`lib/models/game.dart`) com título, descrição e ícone.
2. Crie a tela em `lib/screens/` e registre em `buildGameScreen` (`lib/screens/games_screen.dart`).
3. No fim da partida, abra `GameResultScreen`, que salva a pontuação e mostra o ranking.

As imagens vêm do repositório [PokeAPI/sprites](https://github.com/PokeAPI/sprites)
(arte oficial) e ficam em cache no aparelho. O ícone do app é o Unown "?"
(`assets/icon/`, gerado com `dart run flutter_launcher_icons`).

## Estrutura

```
lib/
  main.dart                   # bootstrap, providers e roteamento login/home
  theme.dart                  # cores (fundo rosado) e tema
  data/pokemon_names.dart     # os 1025 nomes (gerado da PokeAPI)
  models/                     # Pokemon/Region, GameId, QuizLevel, UserProfile
  services/
    database_service.dart     # SQLite (usuários e pontuações por jogo)
    auth_service.dart         # login local + Google, sessão
    quiz_engine.dart          # sorteio do "Quem é esse Pokémon?" e normalização
    hangman_engine.dart       # regras da Forca
  screens/                    # login, abas, jogos, resultado, ranking, perfil
  widgets/                    # fundo de pokébolas, PokemonImage, forca do Banette
test/                         # testes unitários
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
