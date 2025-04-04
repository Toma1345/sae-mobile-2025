# SAE Mobile - IUTables'O

## Membres du projet
- Thomas Brossier
- Kylian Dumas
- Nicolas Nauche

## Description
IUTables'O est une application mobile permettant de découvrir et d'évaluer les restaurants d'Orléans. L'application offre une expérience personnalisée grâce à la gestion des préférences culinaires et aux avis des utilisateurs.

## Installation et Lancement
### Prérequis
- **Android Studio** installé
- **Flutter** installé et configuré
- **Un périphérique Android** (physique ou émulateur)

### Étapes d'installation et de lancement
1. Cloner le projet depuis le dépôt Git :
   ```sh
   git clone https://github.com/Toma1345/sae-mobile-2025.git
   cd sae-mobile-2025
   ```
2. Installer les dépendances Flutter :
   ```sh
   flutter pub get
   ```
3. Lancer l'application :
   - Ouvrir **Android Studio**
   - Sélectionner un périphérique d'exécution (émulateur ou smartphone Android connecté)
   - Cliquer sur **Run** (icône du triangle vert)

   *Testé sous Windows avec un téléphone Samsung pour la partie Android.*
   *Testé sous Chrome et Edge pour la partie Flutter Web.*

## Fonctionnalités Implémentées
- **Inscription et Connexion utilisateur**
- **Choix des préférences culinaires** (types de restaurants et cuisines)
- **Filtrage des restaurants selon les préférences**
- **Filtrage des restaurants selon les favoris**
- **Listing de tous les restaurants**
- **Détail d'un restaurant avec informations d'horaires d'ouverture, cuisines, avis, carte map**
- **Barre de recherche**
- **Filtre selon type de restaurant**
- **Filtre selon ouverture ou fermeture (ou non renseigné)**
- **Ajout/Suppression des restaurants favoris** (stocké dans Supabase)
- **Ajout d'un avis sur un restaurant** (commentaire, note, ajout de photos depuis la galerie ou en direct)
- **Page d'accueil personnalisée** avec les restaurants les plus proches et correspondant aux préférences

## Autres Aspects Techniques
- **Réalisation de tests** sur les pages `login.dart` et `restaurant.dart`
- **Utilisation de Supabase** pour la gestion des restaurants, avis et favoris

---
Ce projet a été réalisé dans le cadre de la SAE Mobile de l'IUT d'Orléans - Département Informatique.

