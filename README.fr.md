# Serpent

[🇺🇸 English](README.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md) · [🇯🇵 日本語](README.ja.md) · [🇰🇷 한국어](README.ko.md) · [🇫🇷 Français](README.fr.md) · [🇩🇪 Deutsch](README.de.md) · [🇪🇸 Español](README.es.md)

Un jeu Snake natif et minimaliste pour les Mac avec puce Apple, développé avec SwiftUI, AppKit et AVFoundation. Aucune dépendance tierce à l'exécution et aucune requête réseau.

## Commandes

| Action | Commande |
| --- | --- |
| Se déplacer | Touches fléchées, WASD ou glisser/balayer sur la grille de jeu |
| Commencer, mettre en pause ou reprendre | Espace |
| Nouvelle partie | R ou ⌘N |
| Mettre en pause ou fermer les réglages/l'aide | Échap |
| Réglages | ⌘, |

Attrapez la nourriture pour faire grandir votre serpent. Heurter un mur met fin à la partie, sauf si « Traverser les bords » est activé. Heurter votre propre corps met toujours fin à la partie. Les demi-tours directs à 180° sont ignorés ; les changements de direction valides effectués rapidement sont mis en file d'attente et appliqués lors des déplacements successifs.

Le jeu se met automatiquement en pause lorsque vous passez à une autre application, réduisez la fenêtre ou mettez votre Mac en veille. À votre retour, appuyez sur Espace pour reprendre.

## Fonctionnalités

- Fenêtre native redimensionnable, avec prise en charge du plein écran et du rendu Retina/haute résolution.
- Apparence claire, sombre ou système. Par défaut, le jeu suit l'apparence de votre Mac.
- Rendu fluide à 60 Hz, nourriture qui pulse doucement et mises à jour animées du score.
- Trois niveaux de difficulté, chacun avec son propre record :

  | Difficulté | Temps par déplacement | Points par nourriture |
  | --- | --- | --- |
  | Facile | 160 ms | 10 |
  | Normal | 105 ms | 20 |
  | Difficile | 70 ms | 30 |

  Les changements de difficulté s'appliquent à la prochaine partie.

- Un interrupteur indépendant **Traverser les bords**, désactivé par défaut, se trouve dans **Réglages → Jeu**. Une fois activé, le serpent qui franchit un bord ressort du côté opposé. Les changements prennent effet à la prochaine partie ; heurter son propre corps termine toujours la partie. Les records sont enregistrés séparément pour chaque difficulté et chaque mode, et les anciens records du mode classique sont conservés.

- Sons doux de synthèse, facultatifs, pour le début de partie, la collecte de nourriture, la pause, la fin de partie et les nouveaux records.
- Records, préférences et choix de langue enregistrés localement.
- Huit langues entièrement traduites, sélectionnables à l'aide de drapeaux dans les Réglages :

  | Langue | Région |
  | --- | --- |
  | 🇺🇸 Anglais | États-Unis |
  | 🇨🇳 Chinois simplifié | Chine |
  | 🇹🇼 Chinois traditionnel | Taïwan |
  | 🇯🇵 Japonais | Japon |
  | 🇰🇷 Coréen | Corée du Sud |
  | 🇫🇷 Français | France |
  | 🇩🇪 Allemand | Allemagne |
  | 🇪🇸 Espagnol | Espagne |

  Par défaut, la langue suit les langues préférées de votre Mac. Vous pouvez la modifier à tout moment dans les Réglages.

## Développement et création des distributions

Les Xcode Command Line Tools et Swift 5.9 ou une version ultérieure sont requis.

```sh
swift test
swift run Serpent
./Scripts/build-app.sh
```

Le script de distribution crée une application arm64 et une archive ZIP, puis vérifie la signature de l'application. Exécutez `BUILD_DMG=1 ./Scripts/build-app.sh` pour générer également une image disque.

La version compilée localement utilise une signature ad hoc et n'a pas été notariée avec un Apple Developer ID. Si macOS bloque l'application après son téléchargement sur un autre Mac, suivez les indications du système pour autoriser son ouverture.

Les tests automatisés couvrent les règles du jeu, la file d'attente des changements de direction, les cas limites, la pause automatique, la sélection de la langue selon le système et l'exhaustivité des traductions dans les huit langues.

Les fichiers source se trouvent dans `Sources/Serpent`, les traductions dans `Sources/Serpent/Resources`, et l'icône ainsi que les métadonnées de l'application dans `Support`.
