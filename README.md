# PharmaCare - Application Mobile Pharmaceutique

<div align="center">

![PharmaCare](https://img.shields.io/badge/PharmaCare-1.0.0-green)
![Flutter](https://img.shields.io/badge/Flutter-3.38.9-blue)
![Dart](https://img.shields.io/badge/Dart-3.10.8-blue)
![License](https://img.shields.io/badge/License-MIT-green)

**Une application pharmaceutique professionnelle avec deux interfaces complètes: Délégué et Entreprise**

[Démarrage Rapide](#-démarrage-rapide) • [Documentation](#-documentation) • [Features](#-features) • [Architecture](#-architecture)

</div>

---

## 🎯 Présentation

**PharmaCare** est une application mobile sophistiquée conçue pour la gestion pharmaceutique. Elle offre deux interfaces complètement différentes:

- 👤 **Interface Délégué**: Pour les représentants pharmaceutiques
- 🏢 **Interface Entreprise**: Pour la gestion administrative

La couleur verte (#27AE60) symbolise le domaine pharmaceutique et professionnalisme.

---

## ✨ Features Principales

### 📱 Interface Délégué
- ✅ Tableeau de bord avec statistiques personnelles
- ✅ Gestion des visites clients programmées
- ✅ Historique des commandes
- ✅ Accès au catalogue produits
- ✅ Actions rapides intuitives
- ✅ Navigation multi-onglets

### 🏢 Interface Entreprise
- ✅ Tableau de bord avec KPIs en temps réel
- ✅ Gestion des délégués
- ✅ Gestion de l'inventaire
- ✅ Rapports de ventes détaillés
- ✅ Classement des meilleurs délégués
- ✅ Suivi des activités récentes
- ✅ Navigation administrative

### 🎨 Design & UX
- ✅ Design Material Design 3 moderne
- ✅ Thème vert cohérent (Pharma)
- ✅ Responsive sur tous les appareils
- ✅ Accessibilité optimale
- ✅ Animations fluides
- ✅ Interface performante

---

## 🚀 Démarrage Rapide

### Prérequis
```bash
Flutter 3.38.9+
Dart 3.10.8+
Chrome (pour web) ou Android/iOS
```

### Installation

1. **Cloner le projet**
```bash
cd c:\Users\MSI\pharma_app
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Lancer l'application**
```bash
# Sur web (recommandé)
flutter run -d chrome

# Sur Android
flutter run -d android

# Sur iOS
flutter run -d ios
```

---

## 📁 Architecture du Projet

```
lib/
├── main.dart                           # Point d'entrée + configuration thème
├── models/
│   └── user_model.dart                # Modèles User et UserRole enum
├── screens/
│   ├── login_screen.dart              # Écran d'authentification
│   ├── delegate_dashboard.dart        # Dashboard délégué
│   └── enterprise_dashboard.dart      # Dashboard entreprise
└── widgets/
    └── delegate_widgets.dart          # Widgets réutilisables
```

---

## 🎨 Palette de Couleurs

| Utilisation | Couleur | Code |
|--|--|--|
| Primaire | Vert PharmaCare | #27AE60 |
| Secondaire | Vert Foncé | #1E8449 |
| Accent | Bleu Ciel | #2980B9 |
| Alerte | Orange | #E67E22 |
| Spécial | Violet | #9B59B6 |

---

## 📝 Interfaces

### 🔓 Écran de Connexion

```
┌─────────────────────────┐
│   🏥 PharmaCare Pro    │
├─────────────────────────┤
│  [👤 Délégué] [🏢 Ent] │
├─────────────────────────┤
│ Email: [____________]   │
│ Mot de passe: [______]  │
│    [Se Connecter]       │
└─────────────────────────┘
```

**Rôles de test:**
- Email: `delegue@pharmacare.fr` → Dashboard Délégué
- Email: `admin@pharmacare.fr` → Dashboard Entreprise

### 👤 Dashboard Délégué

**Sections:**
1. **Bienvenue** - Statistiques personnelles
2. **Actions Rapides** - Nouvelle commande, Visite, etc.
3. **Visites Programmées** - Agenda complet
4. **Commandes Récentes** - Historique

### 🏢 Dashboard Entreprise

**Sections:**
1. **Bienvenue** - KPIs en temps réel
2. **Indicateurs Clés** - Ventes, Commandes, Satisfaction
3. **Gestion** - Délégués, Inventaire, Rapports
4. **Meilleurs Délégués** - Classement
5. **Activités** - Journal des actions

---

## 📚 Documentation

Le projet contient une documentation complète:

### 📖 Fichiers Principaux

1. **[QUICK_START.md](QUICK_START.md)** - Guide de démarrage rapide
2. **[INTERFACE_DOCUMENTATION.md](INTERFACE_DOCUMENTATION.md)** - Doc complète du projet
3. **[GUIDE_UTILISATION.md](GUIDE_UTILISATION.md)** - Guide pour utilisateurs finaux
4. **[DESIGN_SPECIFICATIONS.md](DESIGN_SPECIFICATIONS.md)** - Spécifications UI/UX détaillées

---

## 🔧 Commandes Utiles

```bash
# Vérifier la qualité du code
flutter analyze

# Formater le code
dart format lib/

# Nettoyer et reconstruire
flutter clean
flutter pub get

# Générer une build APK
flutter build apk --release

# Générer une build Web
flutter build web

# Générer une build iOS
flutter build ios --release
```

---

## 🎯 Structure des Données

### Modèle User
```dart
class User {
  final String id;                    // Identifiant unique
  final String email;                 // Email
  final String name;                  // Nom
  final String role;                  // Rôle (texte)
  final UserRole userRole;            // Énumération
  final String company;               // Compagnie
  final String? phone;                // Téléphone optionnel
  final String? region;               // Région optionnelle
}

enum UserRole { delegate, enterprise }
```

---

## ✅ À Savoir

- **Pas de backend réel**: Mode démo avec données mockées
- **Pas de persistance**: Les données se réinitialisent au relancement
- **Aucune validation**: Les identifiants ne sont pas vérifiés
- **UI Uniquement**: La navigation fonctionne mais les actions ne persistent pas

---

## 🚀 Améliorations Futures

- [ ] Intégration API backend
- [ ] Authentification réelle (Firebase/JWT)
- [ ] Base de données locale (SQLite)
- [ ] Notifications push
- [ ] Graphiques et analytics
- [ ] Import/Export de données
- [ ] Support offline
- [ ] Multi-langues (EN, ES, DE, IT)

---

## 🏆 Points Forts

✨ **Professionnel** - Design adapté au secteur pharmaceutique  
✨ **Complet** - Deux interfaces fonctionnelles complètes  
✨ **Moderne** - Technologies et patterns actuels  
✨ **Documenté** - Documentation exhaustive fournie  
✨ **Scalable** - Architecture préparée pour croissance  
✨ **Accessible** - Interface claire et intuitive  

---

<div align="center">

**Créée avec ❤️ pour PharmaCare**

Flutter 3.38.9 | Dart 3.10.8 | Material Design 3

Février 2026 - Version 1.0.0 ✅

</div>
