---
name: entourage-ui
description: >
  Créer, critiquer ou documenter des maquettes UI pour l'application Entourage Local en HTML fidèle au design system officiel.
  Utiliser ce skill dès que la demande concerne : générer un nouvel écran Entourage à partir d'un brief, critiquer une maquette existante par rapport au DS, ou documenter un composant pour le handoff dev. Déclencher même si la demande est formulée informellement ("fais-moi une maquette de X", "est-ce que ça colle au DS ?", "comment documenter ce composant ?"). Ce skill est partagé entre PM et designers de l'équipe Entourage.
---

# Design : Entourage Local UI

Skill pour produire, critiquer et documenter des maquettes HTML fidèles au design system Entourage Local.

**Figma DS de référence** : https://www.figma.com/design/SQnAFKzPtDuiOLcaAaiLUx/DS---Entourage-local

---

## Trois modes d'utilisation

| Mode | Déclencheurs typiques | Output |
|------|----------------------|--------|
| **Générer** | "crée un écran pour X", "maquette de la page Y", "mockup du flow Z" | Fichier HTML rendu |
| **Critiquer** | "est-ce que ça respecte le DS ?", "revue de cette maquette", screenshot fourni | Rapport structuré |
| **Documenter** | "documente ce composant", "spec de handoff pour X" | Spec markdown ou HTML |

---

## Design tokens

### Variables CSS

```css
/* Couleurs principales */
--color-primary:        #FF9739;   /* Orange Local — CTA, accents, liens actifs */
--color-primary-dark:   #D53F00;   /* Pressed / hover */
--color-primary-mid:    #FF9C5D;   /* Medium orange — accents secondaires */
--color-primary-light:  #FEEAE3;   /* Extra light orange — fonds teintés, cards suggestion */
--color-primary-xlight: #FFF8F6;   /* Fond général app */

/* Sémantiques */
--color-green:          #79CC6B;   /* Toggle actif, disponible, badge "Obtenu" */
--color-green-light:    #DEF1E8;   /* Fond succès */
--color-red:            #FE2929;   /* Erreur, état indisponible */

/* Neutres */
--color-bg:             #FFF8F6;   /* Fond général app (PAS blanc pur, PAS gris) */
--color-white:          #FFFFFF;   /* Cards, modales */
--color-text-main:      #363636;   /* Textes principaux */
--color-text-dark:      #222222;   /* Titres forts */
--color-text-secondary: #6D6C6C;   /* Textes secondaires, corps */
--color-text-disabled:  #A0A0A0;   /* Placeholders, inactifs, labels section */
--color-border:         #D9D9D9;   /* Bordures */
--color-separator:      #F5F5F5;   /* Séparateurs légers */

/* Ombres */
--shadow-card:  0 2px 12px rgba(0, 0, 0, 0.06);
--shadow-modal: 0 8px 32px rgba(0, 0, 0, 0.12);
```

### Palette complète

| Groupe | Nom | Hex | Usage |
|--------|-----|-----|-------|
| **Oranges** | Extra extra light | `#FFF8F6` | Fond app général |
| | Extra light | `#FEEAE3` | Fond teinté, cards suggestion |
| | Light | `#FDDCD0` | Fond léger |
| | Medium | `#FF9C5D` | Accents secondaires |
| | **Orange Local** | **`#FF9739`** | **Couleur primaire — CTA, accents** |
| | Orange social | `#F55F24` | Variante sociale |
| | Dark | `#D53F00` | Pressed / hover |
| **Neutres** | White | `#FFFFFF` | Cards, modales |
| | Light gray | `#F5F5F5` | Séparateurs |
| | Gray | `#D9D9D9` | Borders |
| | Medium gray | `#A0A0A0` | Textes désactivés |
| | Dark gray | `#6D6C6C` | Textes secondaires |
| | Black | `#363636` | Textes principaux |
| | Black dark | `#222222` | Titres forts |
| **Verts** | Extra light | `#DEF1E8` | Fond succès |
| | Light | `#A7DB9F` | — |
| | **Green** | **`#79CC6B`** | **Toggle actif, badge "Obtenu"** |
| | Medium | `#1E7F51` | — |
| **Rouges** | Light | `#F1545D` | Alerte légère |
| | Red | `#FE2929` | Erreur, indisponible |
| **Bleus** | Hover | `#ECF8FB` | — |
| | Blue | `#8FC4E2` | — |
| | Primary Pro | `#47A8B9` | Entourage Pro |

### Typographie

**Font family** : `Poppins` (Google Fonts — **PAS Lato**)
Import : `https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap`

| Style | Taille | Poids | Couleur | Usage |
|-------|--------|-------|---------|-------|
| Titre écran | 16px | 600 | `#363636` | Header navigation |
| Titre principal | 20–22px | 600–700 | `#363636` | Titre page/profil |
| Titre section | 16px | 600 | `#363636` | Titre card |
| Label section | 11px | 700 | `#A0A0A0` | **Uppercase + letter-spacing 1px** |
| Corps | 14px | 400 | `#6D6C6C` | Texte courant |
| Caption | 13px | 400 | `#A0A0A0` | Métadonnées, dates |
| Lien / CTA texte | 13–14px | 600 | `#FF9739` | Liens oranges |
| Bouton primaire | 15px | 600 | `#FFFFFF` | — |
| Bouton outline | 15px | 500 | `#363636` | — |

### Spacing & Layout

- Base : **4px** · Valeurs : `4 · 8 · 12 · 16 · 20 · 24 · 32px`
- Padding latéral écran : **20px**
- Viewport : **390px** (iPhone 14)
- Header hauteur : **52px**, fond `#FFF8F6` continu (pas de border-bottom)

| Élément | Border radius |
|---------|---------------|
| Cards | `16px` |
| Boutons (pill) | `32px` |
| Inputs | `12px` |
| Badges | `12px` |
| Cercles / avatars | `50%` |

---

## Composants

### Bouton primaire (CTA plein)
```html
<button style="background:#FF9739; color:#fff; border:none; border-radius:32px;
  padding:14px 28px; font:600 15px 'Poppins',sans-serif; width:100%; cursor:pointer;">
  Voir les prochaines dates
</button>
```
- Pressed : `#D53F00` — Disabled : `opacity 0.4`

### Bouton secondaire (outline)
```html
<button style="background:transparent; color:#363636; border:1.5px solid #FF9739;
  border-radius:32px; padding:13px 28px; font:500 15px 'Poppins',sans-serif; cursor:pointer;">
  Modifier mon profil
</button>
```

### Bouton tertiaire (lien texte)
```html
<span style="font:600 13px 'Poppins'; color:#FF9739; cursor:pointer;">Voir tout »</span>
```

### Header de navigation
```html
<header style="position:fixed; top:0; left:0; right:0; height:52px; background:#FFF8F6;
  display:flex; align-items:center; padding:0 20px; z-index:100; max-width:390px; margin:0 auto;">
  <button style="background:none; border:none; padding:8px; margin-left:-8px; cursor:pointer; font-size:18px; color:#363636;">‹</button>
  <span style="flex:1; text-align:center; font:600 16px 'Poppins'; color:#363636;">Titre</span>
  <button style="background:none; border:none; padding:8px; cursor:pointer; font-size:18px; color:#363636;">⚙</button>
</header>
```
Pas de border-bottom — le fond `#FFF8F6` est continu avec le reste de la page.

### Card standard
```html
<div style="background:#FFFFFF; border-radius:16px; padding:16px 20px;
  box-shadow:0 2px 12px rgba(0,0,0,0.06); margin-bottom:12px;">
  <!-- contenu -->
</div>
```

### Card suggestion (fond teinté)
```html
<div style="background:#FEEAE3; border-radius:16px; padding:20px; margin-bottom:12px;">
  <div style="font:700 12px 'Poppins'; color:#FF9739; text-transform:uppercase; letter-spacing:0.5px; margin-bottom:8px;">Suggestion</div>
  <div style="font:600 16px 'Poppins'; color:#363636; margin-bottom:8px; line-height:1.4;">
    Et si vous participiez à un Papotage solidaire cette semaine ?
  </div>
  <div style="font:400 13px 'Poppins'; color:#6D6C6C; margin-bottom:16px; line-height:1.5;">
    Prenez un moment pour échanger…
  </div>
  <button style="background:#FF9739; color:#fff; border:none; border-radius:32px;
    padding:13px 24px; font:600 15px 'Poppins'; width:100%; cursor:pointer;">
    Voir les prochaines dates
  </button>
</div>
```

### Input
```html
<input style="width:100%; border:1.5px solid #D9D9D9; border-radius:12px;
  padding:12px 16px; font:400 14px 'Poppins',sans-serif; color:#363636;
  background:#fff; box-sizing:border-box;" placeholder="...">
```

### Label de section
```html
<div style="font:700 11px 'Poppins'; color:#A0A0A0; text-transform:uppercase;
  letter-spacing:1px; margin-bottom:12px; margin-top:24px;">
  CE QUE J'AI FAIT
</div>
```

### Badge
```html
<!-- Obtenu -->   <span style="font:700 12px 'Poppins'; color:#79CC6B;">Obtenu</span>
<!-- En cours --> <span style="font:700 12px 'Poppins'; color:#FF9739;">2/3</span>
<!-- Inactif -->  <span style="font:400 12px 'Poppins'; color:#A0A0A0;">Non obtenu</span>
```

### Grille badges (3 colonnes)
```html
<div style="display:grid; grid-template-columns:repeat(3,1fr); gap:10px;">
  <!-- Badge obtenu -->
  <div style="background:#fff; border-radius:12px; padding:14px 8px;
    box-shadow:0 2px 8px rgba(0,0,0,0.06); text-align:center;">
    <div style="font-size:28px; margin-bottom:8px;">👣</div>
    <div style="font:500 12px 'Poppins'; color:#363636; margin-bottom:4px;">Premier pas</div>
    <div style="font:700 12px 'Poppins'; color:#79CC6B;">Obtenu</div>
  </div>
  <!-- Badge en cours -->
  <div style="background:#fff; border-radius:12px; padding:14px 8px;
    box-shadow:0 2px 8px rgba(0,0,0,0.06); text-align:center;">
    <div style="font-size:28px; margin-bottom:8px; opacity:0.4;">☕</div>
    <div style="font:500 12px 'Poppins'; color:#363636; margin-bottom:4px;">As du papotage</div>
    <div style="font:700 12px 'Poppins'; color:#FF9739;">2/3</div>
  </div>
  <!-- Badge non obtenu -->
  <div style="background:#fff; border-radius:12px; padding:14px 8px;
    box-shadow:0 2px 8px rgba(0,0,0,0.06); text-align:center;">
    <div style="font-size:28px; margin-bottom:8px; opacity:0.25;">🤝</div>
    <div style="font:500 12px 'Poppins'; color:#363636; margin-bottom:4px;">Premier lien</div>
    <div style="font:400 12px 'Poppins'; color:#A0A0A0;">Non obtenu</div>
  </div>
</div>
```

### Avatar
```html
<!-- Avec photo -->
<div style="width:80px; height:80px; border-radius:50%; overflow:hidden;
  border:3px solid #fff; box-shadow:0 2px 8px rgba(0,0,0,0.1);">
  <img src="..." style="width:100%; height:100%; object-fit:cover;">
</div>
<!-- Sans photo -->
<div style="width:80px; height:80px; border-radius:50%; background:#FEEAE3;
  display:flex; align-items:center; justify-content:center;
  font:700 28px 'Poppins'; color:#FF9739;">JS</div>
```

### Card stat hero
```html
<div style="background:#fff; border-radius:16px; padding:20px;
  box-shadow:0 2px 12px rgba(0,0,0,0.06); margin-bottom:20px;">
  <div style="font:700 18px 'Poppins'; color:#363636; margin-bottom:6px; line-height:1.3;">
    Vous vous êtes engagée 23 fois au sein de la communauté.
  </div>
  <div style="font:400 13px 'Poppins'; color:#A0A0A0;">Depuis janvier 2026 — 87 actions au total</div>
</div>
```

### Ligne d'activité
```html
<div style="display:flex; align-items:center; gap:14px; padding:14px 0; border-bottom:1px solid #F5F5F5;">
  <div style="width:40px; height:40px; border-radius:50%; background:#FEEAE3;
    display:flex; align-items:center; justify-content:center; flex-shrink:0; font-size:20px;">🎉</div>
  <span style="flex:1; font:400 14px 'Poppins'; color:#6D6C6C;">J'ai participé à des événements</span>
  <span style="font:700 16px 'Poppins'; color:#363636;">5</span>
</div>
```

### Card contenu horizontal (article / entraide)
```html
<div style="background:#fff; border-radius:12px; padding:12px;
  box-shadow:0 2px 8px rgba(0,0,0,0.06); display:flex; gap:12px; margin-bottom:8px;">
  <div style="position:relative; flex-shrink:0;">
    <img src="..." style="width:72px; height:72px; border-radius:8px; object-fit:cover;">
    <span style="position:absolute; bottom:4px; left:4px; background:#FF9739; color:#fff;
      border-radius:10px; padding:2px 8px; font:600 10px 'Poppins';">Comprendre</span>
  </div>
  <div style="flex:1; min-width:0;">
    <div style="font:600 14px 'Poppins'; color:#363636; line-height:1.3; margin-bottom:4px;">
      Déconstruire quelques préjugés sur les personnes sans-abri
    </div>
    <div style="font:400 12px 'Poppins'; color:#A0A0A0;">3 mn de lecture</div>
  </div>
</div>
```

### Card événement (image full-width, scroll horizontal)
```html
<div style="background:#fff; border-radius:12px; overflow:hidden;
  box-shadow:0 2px 8px rgba(0,0,0,0.06); display:inline-block; width:180px; margin-right:12px; vertical-align:top;">
  <div style="position:relative;">
    <img src="event.jpg" style="width:100%; height:110px; object-fit:cover; display:block;">
    <span style="position:absolute; bottom:6px; left:8px; background:#FF9739; color:#fff;
      border-radius:10px; padding:2px 8px; font:600 10px 'Poppins';">🏃 Sport</span>
  </div>
  <div style="padding:10px 10px 12px;">
    <div style="font:600 13px 'Poppins'; color:#363636; margin-bottom:4px;">Paris sports - Yoga</div>
    <div style="font:400 11px 'Poppins'; color:#A0A0A0;">12.07.2022</div>
    <div style="font:400 11px 'Poppins'; color:#A0A0A0;">Parc de Bercy, Paris</div>
  </div>
</div>
```

### Tags thématiques (pills multicolores)
```html
<div style="display:flex; flex-wrap:wrap; gap:8px; margin-bottom:12px;">
  <span style="border:1.5px solid #FF9739; color:#FF9739; border-radius:20px; padding:4px 12px; font:500 12px 'Poppins';">Art et culture</span>
  <span style="border:1.5px solid #79CC6B; color:#79CC6B; border-radius:20px; padding:4px 12px; font:500 12px 'Poppins';">Cuisine</span>
  <span style="border:1.5px solid #47A8B9; color:#47A8B9; border-radius:20px; padding:4px 12px; font:500 12px 'Poppins';">Jeux</span>
  <span style="border:1.5px solid #FF9C5D; color:#FF9C5D; border-radius:20px; padding:4px 12px; font:500 12px 'Poppins';">Sport</span>
</div>
```

### Post (fil de groupe)
```html
<div style="background:#fff; border-radius:12px; padding:16px;
  box-shadow:0 2px 8px rgba(0,0,0,0.06); margin:0 16px 12px;">
  <div style="display:flex; align-items:center; gap:10px; margin-bottom:10px;">
    <img src="avatar.jpg" style="width:40px; height:40px; border-radius:50%; object-fit:cover;">
    <div style="flex:1;">
      <div style="font:600 13px 'Poppins'; color:#363636;">John Doe</div>
      <div style="font:400 11px 'Poppins'; color:#A0A0A0;">12.01.22</div>
    </div>
    <button style="background:none; border:none; cursor:pointer; color:#A0A0A0; font-size:18px;">···</button>
  </div>
  <p style="font:400 14px 'Poppins'; color:#6D6C6C; line-height:1.5; margin-bottom:12px;">
    Bienvenue à toi cher danseur ! Nous sommes prêts pour les beaux jours :-)
  </p>
  <div style="display:flex; gap:0; border-top:1px solid #F5F5F5; padding-top:10px;">
    <button style="flex:1; background:none; border:none; cursor:pointer;
      font:500 13px 'Poppins'; color:#6D6C6C; display:flex; align-items:center; justify-content:center; gap:6px; padding:6px;">
      👍 J'aime
    </button>
    <button style="flex:1; background:none; border:none; cursor:pointer;
      font:500 13px 'Poppins'; color:#6D6C6C; display:flex; align-items:center; justify-content:center; gap:6px; padding:6px;">
      💬 Commenter
    </button>
  </div>
</div>
```

### Sondage (dans un post)
```html
<div style="margin-bottom:12px;">
  <div style="font:500 12px 'Poppins'; color:#A0A0A0; margin-bottom:8px;">Sélectionnez une option</div>
  <!-- Option sélectionnée -->
  <div style="display:flex; align-items:center; gap:10px; margin-bottom:8px;">
    <div style="width:20px; height:20px; border-radius:50%; background:#FF9739;
      display:flex; align-items:center; justify-content:center; flex-shrink:0;">
      <div style="width:8px; height:8px; border-radius:50%; background:#fff;"></div>
    </div>
    <div style="flex:1;">
      <div style="font:500 13px 'Poppins'; color:#363636; margin-bottom:4px;">Super motivée !</div>
      <div style="height:4px; background:#F5F5F5; border-radius:2px;">
        <div style="width:30%; height:100%; background:#FF9739; border-radius:2px;"></div>
      </div>
    </div>
    <span style="font:400 12px 'Poppins'; color:#A0A0A0; flex-shrink:0;">1</span>
  </div>
  <div style="text-align:center; margin-top:8px;">
    <span style="font:500 13px 'Poppins'; color:#A0A0A0; cursor:pointer;">Voir les votes</span>
  </div>
</div>
```

### En-tête groupe (titre + membres + boutons)
```html
<div style="padding:16px 20px;">
  <h1 style="font:700 22px 'Poppins'; color:#363636; margin-bottom:8px;">Groupe de voisins à Paris</h1>
  <div style="display:flex; align-items:center; gap:8px; margin-bottom:16px;">
    <div style="display:flex;">
      <img src="a1.jpg" style="width:28px; height:28px; border-radius:50%; border:2px solid #fff; margin-right:-8px; object-fit:cover;">
      <img src="a2.jpg" style="width:28px; height:28px; border-radius:50%; border:2px solid #fff; margin-right:-8px; object-fit:cover;">
      <img src="a3.jpg" style="width:28px; height:28px; border-radius:50%; border:2px solid #fff; object-fit:cover;">
    </div>
    <span style="font:400 13px 'Poppins'; color:#A0A0A0;">··· Paris, 75000</span>
  </div>
  <div style="display:flex; gap:10px; margin-bottom:16px;">
    <button style="flex:1; background:transparent; color:#363636; border:1.5px solid #D9D9D9;
      border-radius:32px; padding:10px 16px; font:500 14px 'Poppins'; cursor:pointer;">Partager ↗</button>
    <button style="flex:1; background:#FF9739; color:#fff; border:none;
      border-radius:32px; padding:10px 16px; font:600 14px 'Poppins'; cursor:pointer;">Rejoindre ⊕</button>
  </div>
</div>
```

### Header accueil (fond orange)
```html
<header style="background:#FF9739; padding:12px 16px; display:flex; align-items:center; gap:12px;">
  <img src="avatar.jpg" style="width:36px; height:36px; border-radius:50%; object-fit:cover;">
  <div style="flex:1; text-align:center;">
    <div style="font:700 18px 'Poppins'; color:#fff; letter-spacing:-0.5px;">entourage</div>
    <div style="font:400 10px 'Poppins'; color:rgba(255,255,255,0.85);">L'app qui recrée le lien entre voisins</div>
  </div>
  <button style="background:rgba(255,255,255,0.2); border:none; border-radius:50%;
    width:36px; height:36px; display:flex; align-items:center; justify-content:center; cursor:pointer;">🔔</button>
</header>
```

### Section feed (titre + sous-titre + lien "Voir tout")
```html
<section style="padding:20px 16px 0;">
  <div style="font:700 16px 'Poppins'; color:#363636; margin-bottom:4px;">Donner un coup de pouce</div>
  <div style="font:400 13px 'Poppins'; color:#A0A0A0; margin-bottom:14px;">Vos voisins ont besoin de vous !</div>
  <!-- cards -->
  <div style="text-align:right; margin-top:10px;">
    <span style="font:600 13px 'Poppins'; color:#FF9739; cursor:pointer;">Voir toutes les demandes ›</span>
  </div>
</section>
```

### Bottom navigation
```html
<nav style="position:fixed; bottom:0; left:0; right:0; max-width:390px; margin:0 auto;
  height:64px; background:#fff; display:flex; align-items:center;
  box-shadow:0 -2px 8px rgba(0,0,0,0.06); z-index:100;">
  <!-- Actif -->
  <a href="#" style="flex:1; display:flex; flex-direction:column; align-items:center; gap:2px; text-decoration:none; color:#FF9739;">
    <span style="font-size:20px;">🏠</span>
    <span style="font:600 10px 'Poppins';">Accueil</span>
  </a>
  <!-- Inactifs -->
  <a href="#" style="flex:1; display:flex; flex-direction:column; align-items:center; gap:2px; text-decoration:none; color:#A0A0A0;">
    <span style="font-size:20px;">🤝</span>
    <span style="font:400 10px 'Poppins';">Entraide</span>
  </a>
  <a href="#" style="flex:1; display:flex; flex-direction:column; align-items:center; gap:2px; text-decoration:none; color:#A0A0A0;">
    <span style="font-size:20px;">💬</span>
    <span style="font:400 10px 'Poppins';">Discussions</span>
  </a>
  <a href="#" style="flex:1; display:flex; flex-direction:column; align-items:center; gap:2px; text-decoration:none; color:#A0A0A0;">
    <span style="font-size:20px;">👥</span>
    <span style="font:400 10px 'Poppins';">Groupes</span>
  </a>
  <a href="#" style="flex:1; display:flex; flex-direction:column; align-items:center; gap:2px; text-decoration:none; color:#A0A0A0;">
    <span style="font-size:20px;">📅</span>
    <span style="font:400 10px 'Poppins';">Événements</span>
  </a>
</nav>
```

### Bandeau ambassadrice
```html
<div style="background:#FF9739; border-radius:16px; padding:14px 16px; margin:0 16px 24px;
  display:flex; align-items:center; gap:12px;">
  <img src="violette.jpg" style="width:44px; height:44px; border-radius:50%; object-fit:cover; flex-shrink:0;">
  <div>
    <div style="font:600 13px 'Poppins'; color:#fff;">Une question ?</div>
    <div style="font:400 12px 'Poppins'; color:rgba(255,255,255,0.85);">Contactez Violette d'Entourage</div>
  </div>
</div>
```

### Home indicator
```html
<div style="display:flex; justify-content:center; padding:8px 0 12px;">
  <div style="width:134px; height:5px; background:#363636; border-radius:3px; opacity:0.2;"></div>
</div>
```

### Empty state
```html
<div style="display:flex; flex-direction:column; align-items:center;
  justify-content:center; padding:48px 32px; text-align:center;">
  <div style="width:72px; height:72px; border-radius:50%; background:#FEEAE3;
    display:flex; align-items:center; justify-content:center; font-size:32px; margin-bottom:16px;">🔍</div>
  <div style="font:600 16px 'Poppins'; color:#363636; margin-bottom:8px;">Rien ici pour l'instant</div>
  <div style="font:400 14px 'Poppins'; color:#A0A0A0; line-height:1.5;">Message bienveillant et court.</div>
</div>
```

---

## Patterns d'interaction

### Contexte produit

Deux profils utilisateurs :
- **Riverains** : bénévoles/voisins, ont du temps à donner
- **Personnes isolées** : cherchent du lien, des événements, du soutien

Adapter le ton et les CTA en fonction du profil cible.

### Écran Accueil — structure verticale

**Header** : fond orange `#FF9739`, avatar gauche, logo centré, cloche droite.

**Sections dans l'ordre** :
1. Se sensibiliser (articles)
2. Donner un coup de pouce (entraide)
3. Participer à un événement solidaire (scroll horizontal)
4. Tout savoir pour passer à l'action (contenus pédagogiques)
5. Vos groupes de voisins (scroll horizontal)
6. Découvrir des adresses utiles (carte)
7. Vous êtes perdu ? (bandeau ambassadrice)

### Écran détail groupe — structure

1. Header fixe (fond blanc, flèche retour + engrenage)
2. Illustration hero custom (pas de photo), fond `#FFF8F6`, ~180px
3. Zone infos : titre + avatars membres empilés + ville
4. Boutons côte à côte : "Partager" outline gris · "Rejoindre" orange
5. Description + tags thématiques multicolores + "Voir moins" orange
6. Bandeau "Temps de partage" fond `#FEEAE3`
7. Fil de posts
8. Card événement recommandé

### Gamification (badges)

Badges : Premier pas 👣 · Premier lien 🤝 · As du papotage ☕ · Tisseur du quotidien 🌱 · Diffuseur de liens 💫

- Obtenu : icône pleine + label vert `#79CC6B`
- En cours : icône `opacity 0.4` + fraction orange `#FF9739`
- Non obtenu : icône `opacity 0.25` + label gris `#A0A0A0`

Affichage : bottom sheet animée à la délivrance, puis visible sur profil. Grille 3 colonnes.

---

## Ton éditorial (micro-copy)

- **Vous** (pas tutoiement dans l'app)
- **Concret et local** : "à 6km de moi", "vos voisins", "à proximité"
- **Bienveillant** : jamais de culpabilisation
- **Court** : 2 lignes max pour messages système
- **Emoji** : dans les notifications et titres de sections, pas dans les labels UI purs
- **Exemples CTA** : "Voir toutes les demandes ›", "Rejoindre ⊕", "Partager ↗"

---

## Mode GÉNÉRER — structure HTML obligatoire

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=390">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Poppins', sans-serif; background: #FFF8F6;
           max-width: 390px; margin: 0 auto; min-height: 100vh; }
  </style>
</head>
<body>
  <!-- Structure : header fixe (fond #FFF8F6) → contenu scrollable → home indicator -->
</body>
</html>
```

### Checklist avant livraison
- [ ] Viewport 390px (iPhone 14)
- [ ] Police **Poppins** depuis Google Fonts (**PAS Lato**)
- [ ] Fond global `#FFF8F6` (beige chaud — **PAS gris, PAS blanc**)
- [ ] Header fond `#FFF8F6` sans border-bottom
- [ ] Toutes les couleurs issues des tokens
- [ ] Cards blanches `#fff`, `border-radius:16px`, ombre légère
- [ ] Boutons `border-radius:32px`
- [ ] Labels de section uppercase + letter-spacing
- [ ] Home indicator en bas
- [ ] Contenu réaliste (pas de lorem ipsum)

### Workflow

1. Analyser le brief : quel écran, quel profil (Riverain vs Personne isolée), quel objectif
2. Identifier les composants DS nécessaires
3. Générer le HTML complet avec contenu réaliste
4. Vérifier la checklist
5. Livrer avec une note sur les choix non évidents

---

## Mode CRITIQUER — grille d'évaluation

### 1. Conformité tokens (critique)
- Les couleurs sont-elles exactement celles du DS ?
- La typo est-elle Poppins avec les bons poids/tailles ?
- Les espacements respectent-ils la grille 4px ?

### 2. Cohérence composants (critique)
- Les boutons ont-ils le bon style (pill, orange, Poppins 700) ?
- Les cards ont-elles le bon border-radius et shadow ?
- Les inputs respectent-ils le style défini ?

### 3. Hiérarchie visuelle (important)
- L'action principale est-elle clairement mise en avant ?
- L'œil suit-il un parcours logique ?

### 4. Adaptation mobile (important)
- Cibles tactiles ≥ 44px ?
- Pas de contenu trop serré sur 390px ?
- Bottom nav correctement géré ?

### 5. Contenu & ton (utile)
- Langage en accord avec la charte Entourage (bienveillant, direct, inclusif) ?
- Pas de jargon technique visible à l'utilisateur ?

### Format du rapport
```
## Critique maquette — [nom de l'écran]

### ✅ Points conformes
- ...

### ⚠️ Écarts mineurs
- [élément] : [problème] → [correction suggérée]

### 🚨 Écarts bloquants
- [élément] : [problème] → [correction obligatoire]

### Score global : X/5
```

---

## Mode DOCUMENTER — spec de handoff

```markdown
## [Nom du composant]

**Usage** : quand utiliser ce composant
**Variants** : liste des états/variants

### Anatomie
[schéma HTML commenté ou liste des éléments]

### Tokens appliqués
| Propriété | Token | Valeur |
|-----------|-------|--------|
| background | --color-primary | #FF9739 |

### États
- Default : ...
- Hover/Pressed : ...
- Disabled : opacity 0.5, cursor not-allowed
- Loading : spinner orange centré

### Accessibilité
- role, aria-label si nécessaire
- Contraste AA minimum

### À ne pas faire
- ...
```
