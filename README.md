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

No **modo infinito**, você escolhe um dos 4 levels e joga sem fim, com 3 vidas
(cada erro custa uma) e o botão **Encerrar** para parar e salvar. Tem ranking
próprio ("Quem é esse? Infinito"), somando os pontos; levels mais difíceis valem
mais por acerto.

Respostas em menos de 5s ganham até +50%. Na resposta digitada, maiúsculas,
acentos, espaços e pontuação são ignorados (`mr mime` = `Mr. Mime`).

**Forca** — sorteia um Pokémon e você escolhe letras. São 5 erros permitidos; a cada
erro uma parte do **Banette** aparece na forca. Cada Pokémon descoberto vale
10 + 5 por chance sobrando, e a partida segue até o Banette ficar completo.
A dica mostra a região do Pokémon.

**Qual é o diferente?** — quatro Pokémon num quadrado 2x2 e um critério sorteado
(tipo, método de evolução, primeira letra, forma Mega, região, estágio da evolução,
cor da forma shiny, habilidade, ataque ou lendário/mítico). Três compartilham algo
e um não: toque nele. A pontuação é a sequência de acertos até o primeiro erro.
Depois de cada resposta aparece o valor de cada Pokémon no critério.

Os dados vêm de `assets/data/pokedex.json`, gerado a partir dos CSVs da PokeAPI.
A cor shiny foi calculada a partir da arte oficial shiny; Pokémon com cores muito
misturadas ficam fora das perguntas de cor.

**Quem tem mais?** — dois Pokémon lado a lado e um status sorteado (HP, Ataque,
Defesa, Ataque Especial, Defesa Especial, Velocidade ou Total). Toque no que tem o
valor maior e vem outro par. São 3 vidas; a pontuação é o total de acertos.
Evoluções (2º e 3º estágio) aparecem com mais frequência, e entram também ~200
formas extras com status próprios: Megas, Primal, formas regionais (Alola, Galar,
Hisui, Paldea) e alternativas como Deoxys Attack, Rotom Heat ou Kyurem Black. Os status base também vêm da PokeAPI (`assets/data/pokedex.json`).

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
  models/dex.dart             # tipos, evolução, habilidades... (assets/data/pokedex.json)
  models/                     # Pokemon/Region, GameId, QuizLevel, UserProfile
  services/
    auth_service.dart         # Firebase Auth (e-mail/senha) + perfil no Firestore
    score_service.dart        # ranking global no Firestore
    photo_encoder.dart        # recorta/comprime a foto do perfil
    quiz_engine.dart          # sorteio do "Quem é esse Pokémon?" e normalização
    hangman_engine.dart       # regras da Forca
    odd_one_out_engine.dart   # rodadas do "Qual é o diferente?"
    stat_duel_engine.dart     # pares do "Quem tem mais?"
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
5. O projeto atual (`pokequiz-575ea`) já está configurado para Android em
   `lib/firebase_options.dart`. Para trocar de projeto ou adicionar o iOS, gere a configuração:

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

## Instalar no celular (APK de teste)

A cada push, o workflow `.github/workflows/android.yml` roda análise e testes,
gera o APK e publica uma **Release** com o arquivo `pokequiz.apk`. Link fixo para
a versão mais recente:

https://github.com/hericos/PokeQuiz/releases/latest/download/pokequiz.apk

Os APKs de teste são assinados sempre com a mesma chave
(`android/app/pokequiz-test.keystore`, senha `android`, versionada de propósito)
e a versão sobe a cada build (`1.0.<número do build>`), então o Android aceita
instalar **por cima** da versão anterior, sem desinstalar.

## Build para a Play Store

A chave de teste é pública e **não** deve ser usada na Play Store. Para publicar:

1. Gere a sua chave: `keytool -genkey -v -keystore pokequiz.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pokequiz`
2. Crie `android/key.properties` (já está no `.gitignore`):

```properties
storePassword=...
keyPassword=...
keyAlias=pokequiz
storeFile=/caminho/para/pokequiz.jks
```

3. `flutter build appbundle` gera o `.aab` para enviar ao Play Console.

Com `key.properties` presente, o build de release usa essa chave; sem ele, usa a de teste.

## Versão web (Firebase Hosting)

O mesmo código roda no navegador: https://pokequiz-575ea.web.app

- Build local: `flutter build web --release --no-web-resources-cdn` (gera `build/web`).
  O `--no-web-resources-cdn` embute o motor gráfico no site, sem depender do CDN do Google.
- Teste local: `flutter run -d chrome`.
- Em telas largas o app fica numa coluna de 600px centralizada.
- Deploy: o job `web` do workflow publica no Firebase Hosting a cada push, desde que exista
  o secret `FIREBASE_SERVICE_ACCOUNT_POKEQUIZ_575EA` (ou `FIREBASE_SERVICE_ACCOUNT`) no GitHub. Manual: `firebase deploy --only hosting`.

Para criar o secret, o jeito mais simples é `firebase init hosting:github` (cria a conta de
serviço e o secret sozinho). Manualmente: Google Cloud Console → IAM → Contas de serviço →
criar conta com os papéis **Firebase Hosting Admin**, **Cloud Run Viewer** e **API Keys
Viewer** → Chaves → Adicionar chave JSON → colar o JSON em GitHub → Settings → Secrets and
variables → Actions → `FIREBASE_SERVICE_ACCOUNT`.

## iOS (futuro)

O projeto já inclui a pasta `ios/` e as permissões de câmera/galeria no `Info.plist`.
Ao rodar `flutterfire configure` com `ios`, o `GoogleService-Info.plist` é criado.
O Firebase exige iOS 15+ (ajuste `platform :ios` no `ios/Podfile`).
