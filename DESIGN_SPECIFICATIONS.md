# 🎨 Spécifications de Design UI/UX - PharmaCare

## 📐 Palette de Couleurs

### Couleurs Principales
```dart
// Theme Principal - Vert Pharmaceutique
Primary Green: #27AE60 (Color(0xFF27AE60))
Dark Green: #1E8449 (Color(0xFF1E8449))

// Dégradé Connexion
Gradient Start: #27AE60
Gradient End: #1E8449
```

### Couleurs d'Accent
```dart
Sky Blue: #2980B9 (Color(0xFF2980B9))
Orange: #E67E22 (Color(0xFFE67E22))
Purple: #9B59B6 (Color(0xFF9B59B6))
```

### Couleurs de Statut
```dart
Success: #27AE60 (Vert)
Warning: #E67E22 (Orange)
Neutral: #95A5A6 (Gris)
Error: #E74C3C (Rouge)
```

---

## 🔤 Typographie

### Polices
```dart
Font Family: 'Roboto'
Poids: Regular (400), Medium (500), Bold (700)
```

### Tailles et Styles

| Usage | Size | Weight | Color |
|-------|------|--------|-------|
| App Title | 36px | Bold | #27AE60 |
| Page Title | 24px | Bold | #000000 |
| Section Header | 18px | Bold | #000000 |
| Body Text | 14px | Regular | #333333 |
| Label | 12px | Regular | #666666 |
| Small Text | 11px | Regular | #999999 |

---

## 📐 Dimensionnement

### Espacement (Padding/Margin)
```dart
XS: 4px
S:  8px
M:  12px
L:  16px
XL: 20px
XXL: 24px
XXXL: 32px
```

### Rayons de Bordure
```dart
Small: 6px
Medium: 12px
Large: 16px
Extra Large: 20px
Circle: 50% (BorderRadius.circular(100))
```

### Élevations (Box Shadow)
```dart
Low: blurRadius 5, offset (0, 2)
Medium: blurRadius 10, offset (0, 5)
High: blurRadius 20, offset (0, 10)
```

---

## 🎭 Composants UI

### Boutons

#### Bouton Principal (Elevated)
```dart
Background: #27AE60
Text Color: #FFFFFF
Padding: 16px horizontal, 12px vertical
Border Radius: 12px
Font Weight: Bold
Shadow: High elevation
```

#### Bouton Secondaire (Text)
```dart
Background: Transparent
Text Color: #27AE60
Border: 2px #27AE60
```

#### Bouton Tertaire (Outlined)
```dart
Background: #27AE60.withOpacity(0.1)
Border: 2px #27AE60
Text Color: #27AE60
```

### Champs de Texte

```dart
Background: #FFFFFF
Border: 1px #E0E0E0
Border Radius: 12px
Focused Border: 2px #27AE60
Padding: 12px
Icon Color: #27AE60.withOpacity(0.7)
Hint Color: Text.withOpacity(0.5)
```

### Cartes (Cards)

```dart
Background: Blanc ou Gris[50]
Border: 1px Gris[200]
Border Radius: 12px
Padding: 16px
Shadow: Medium elevation
```

### Items de Liste

```dart
Height: 60-80px
Padding: 16px
Divider: Gris[200]
Icon Container: Color.withOpacity(0.1)
```

---

## 🎯 Layouts

### Dashboard Layout
```
┌──────────────────────────────┐
│ App Bar (Vert #27AE60)       │
├──────────────────────────────┤
│ Welcome Card (Vert Foncé)   │
├──────────────────────────────┤
│ Quick Actions (2x2 Grid)     │
├──────────────────────────────┤
│ Section 1                    │
│ - Item 1                     │
│ - Item 2                     │
│ - Item 3                     │
├──────────────────────────────┤
│ Section 2                    │
│ - Item 1                     │
│ - Item 2                     │
├──────────────────────────────┤
│ Bottom Navigation Bar        │
└──────────────────────────────┘
```

### Grille d'Actions Rapides
```dart
crossAxisCount: 2
mainAxisSpacing: 16px
crossAxisSpacing: 16px
```

---

## 🎬 Animations et Transitions

### Animations Supportées
```dart
Material Transitions (400ms):
- FadeTransition
- SlideTransition
- ScaleTransition

Interactive:
- onTap: Changement couleur/ombrage
- onHover: Animations de survol
```

### Indicateurs de Chargement
```dart
Loader Style: CircularProgressIndicator
Color: #27AE60
Size: 24px
```

---

## 📱 Responsive Design

### Breakpoints
```dart
Mobile: < 480px (Full width - 16px padding)
Tablet: 480px - 1024px (Layouts adaptés)
Desktop: > 1024px (Layouts avec sidebar)
```

### Comportements
```
- Colonnes: 1 col (SM), 2 cols (MD), 3+ cols (LG)
- Padding: Réduit sur mobile, augmenté sur desktop
- Fonts: Légèrement réduites sur mobile
- Navigation: Bottom bar mobile, TOP bar desktop
```

---

## 🖼️ Icones

### IconData Utilisées
```dart
Icons.local_pharmacy        // Logo/Pharmacie
Icons.home                  // Accueil
Icons.shopping_cart         // Commandes
Icons.calendar_today        // Agenda
Icons.person                // Profil
Icons.notifications_none    // Notifications
Icons.domain                // Entreprise
Icons.email                 // Email
Icons.lock                  // Mot de passe
Icons.visibility            // Afficher
Icons.visibility_off        // Masquer
Icons.shopping_bag          // Commande
Icons.people                // Personnes
Icons.inventory             // Inventaire
Icons.bar_chart             // Statistiques
Icons.trending_up           // Tendance
Icons.star                  // Évaluation
```

---

## 🌈 Gradients

### Gradient Connexion
```dart
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [#27AE60, #1E8449]
)
```

### Gradients de Cartes
```dart
Background: Color.withOpacity(0.1) - 0.2
Utilisés pour distinction visuelle
```

---

## ✨ États des Éléments

### Boutons
```
Normal: Full color
Hover: Darken by 10%
Pressed: Darken by 20%
Disabled: Grey with opacity 0.5
```

### Champs
```
Normal: Border gris clair
Focused: Border vert #27AE60 (2px)
Error: Border rouge
```

### Cartes
```
Normal: Ombre légère
Hover: Ombre importante
```

---

## 📊 Composants de Données

### Cartes de Statistiques
```
Layout:
┌─────────────┐
│ Icone       │
├─────────────┤
│ Valeur XXX  │
├─────────────┤
│ Label       │
└─────────────┘

Couleurs: Var par section
```

### Listes de Viaje/Commandes
```
┌────────────────────────────────┐
│ [Icon] | Titre          | Info  │
│        | Subtitle            │
└────────────────────────────────┘
```

### Status Badges
```
Success (Vert): Livré ✅
Warning (Orange): En cours ⏳
Neutral (Gris): Annulé ✗
```

---

## 🎨 Thème Clair Uniquement

- **Mode Sombre**: Non implémenté
- **Brightness**: Light
- **useMaterial3**: true

La palette de couleurs est optimisée pour un environnement clinique/professionnel.

---

## 📝 Conventions de Nommage

### Couleurs
```dart
const primaryGreen = Color(0xFF27AE60);
const darkGreen = Color(0xFF1E8449);
const accentBlue = Color(0xFF2980B9);
// etc.
```

### Marges
```dart
const EdgeInsets.all(16) // Standard
const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
```

### TextStyles
```dart
const TextStyle titleLarge // Titre principal
const TextStyle bodyMedium  // Texte normal
const TextStyle labelSmall  // Label/petit texte
```

---

## 🎯 Objectifs de Design

✨ **Professionnel**: Approprié pour domaine pharmaceutique  
✨ **Accessible**: Contraste suffisant, textes lisibles  
✨ **Efficace**: Navigation claire, actions rapides  
✨ **Moderne**: Design Material 3 contemporain  
✨ **Cohérent**: Thème unifié sur toute l'app  
✨ **Responsive**: Fonctionne sur tous appareils  

---

Dernière mise à jour: Février 2026  
Design System Version: 1.0
