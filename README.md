# PokeQuiz

Quiz de Pokémon feito em **Flutter** (Android agora, iOS no futuro).

## Funcionalidades

- **Conta com e-mail e senha no Firebase Auth**, com "Esqueci minha senha" e exclusão de conta.
- **Perfil no Firestore** (vale em qualquer aparelho): foto (galeria ou câmera), nome, idade, cidade, país, Pokémon preferido (busca por nome ou número) e bio.
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

**Global**, no Firestore. Ao fim de cada partida aparece sua posição. Há ranking por
jogo (melhor partida) e geral (soma dos recordes), com títulos de *Treinador Iniciante*
a *Mestre Pokémon*.

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
  main.dart                   # inicializa o Firebase, providers e roteamento
  firebase_options.dart       # gerado pelo `flutterfire configure`
  theme.dart                  # cores (fundo rosado) e tema
  data/pokemon_names.dart     # os 1025 nomes (gerado da PokeAPI)
  models/                     # Pokemon/Region, GameId, QuizLevel, UserProfile
  services/
    auth_service.dart         # Firebase Auth (e-mail/senha) + perfil no Firestore
    score_service.dart        # ranking global no Firestore
    photo_encoder.dart        # recorta/comprime a foto do perfil
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

## Configurar o Firebase (uma vez)

Sem isso o app abre numa tela "Firebase não configurado".

1. Em https://console.firebase.google.com crie um projeto (ex.: `pokequiz`). Pode desativar o Google Analytics.
2. **Authentication → Começar → Método de login → E-mail/senha → Ativar**.
3. **Firestore Database → Criar banco de dados** → modo de **produção** → região `southamerica-east1` (São Paulo).
4. Publique as regras de segurança: copie o conteúdo de [`firestore.rules`](firestore.rules) em
   **Firestore → Regras → Publicar** (ou `firebase deploy --only firestore:rules`).
5. No seu PC, gere a configuração do app:

```bash
npm install -g firebase-tools        # ou o instalador standalone do Firebase CLI
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=<id-do-projeto> --platforms=android,ios
```

   Isso sobrescreve `lib/firebase_options.dart` e cria `android/app/google-services.json`
   (e o equivalente do iOS). **Faça commit desses arquivos**: eles não são segredos
   (a segurança vem das regras do Firestore), e assim o GitHub Actions gera o APK já configurado.

Tudo isso cabe no plano gratuito (Spark). A foto do perfil é guardada comprimida
no próprio documento do Firestore, por isso não é preciso o Cloud Storage (que exige plano pago).

### Dados no Firestore

| Coleção | Conteúdo | Quem lê |
|---|---|---|
| `users/{uid}` | perfil completo e foto | só o próprio usuário |
| `leaderboard/{uid}` | nome, miniatura, recorde por jogo e total | qualquer usuário logado |

As pontuações são enviadas pelo próprio app, então um usuário mal-intencionado
poderia forjar um recorde. Para um ranking à prova de trapaça, o próximo passo seria
validar as partidas numa Cloud Function.

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
Ao rodar `flutterfire configure` com `ios`, o `GoogleService-Info.plist` é criado.
O Firebase exige iOS 15+ (ajuste `platform :ios` no `ios/Podfile`).
