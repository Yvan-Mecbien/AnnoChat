# 🔒 AnonChat – Anonymous Chat App

> Flutter + Node.js + MongoDB + Socket.IO | Anonymat asymétrique

---

## 📁 Structure

```
/
├── backend/          → Node.js API + Socket.IO
└── flutter_app/      → Application Flutter
```

---

## 🚀 Backend – Setup

### 1. Installation

```bash
cd backend
npm install
cp .env.example .env
# Éditez .env avec vos valeurs
```

### 2. Variables d'environnement clés

| Variable | Description |
|---|---|
| `MONGODB_URI` | URI MongoDB Atlas |
| `JWT_ACCESS_SECRET` | Clé secrète JWT access (256 bits) |
| `JWT_REFRESH_SECRET` | Clé secrète JWT refresh (256 bits) |
| `FRONTEND_URL` | URL de l'app front |
| `BASE_URL` | URL de base pour les liens chat |

### 3. Lancer

```bash
npm run dev      # développement (nodemon)
npm start        # production
```

### 4. Endpoints

| Méthode | Route | Description |
|---|---|---|
| POST | `/api/auth/register` | Inscription |
| POST | `/api/auth/login` | Connexion |
| POST | `/api/auth/refresh` | Refresh token |
| GET | `/api/auth/me` | Profil courant |
| GET | `/api/conversations` | Liste des conversations |
| POST | `/api/conversations/find-or-create` | Ouvrir une conv |
| GET | `/api/messages/:id` | Messages (paginated) |
| POST | `/api/messages` | Envoyer un message (REST) |

### 5. Socket.IO Events

**Client → Serveur**
```
room:join      { conversationId }
message:send   { conversationId, content }
typing:start   { conversationId }
typing:stop    { conversationId }
message:read   { conversationId }
```

**Serveur → Client**
```
message:new    { _id, content, isMine, senderDisplay, ... }
typing:start   { userId }
typing:stop    { userId }
user:online    { userId }
user:offline   { userId, lastSeen }
message:read   { conversationId, readBy }
```

---

## 📱 Flutter – Setup

### 1. Configuration

Modifiez dans `lib/services/api_service.dart` :
```dart
const _baseUrl = 'https://VOTRE_API/api';
```

Et dans `lib/services/socket_service.dart` :
```dart
const _socketUrl = 'https://VOTRE_API';
```

### 2. Installation

```bash
cd flutter_app
flutter pub get
flutter pub run build_runner build
```

### 3. Run

```bash
flutter run
```

---

## 🧠 Logique d'anonymat asymétrique

```
Conversation {
  linkOwner: User A
  visitor:   User B
}

Quand User A (owner) consulte :
  → L'autre s'affiche "Anonyme"
  → senderId du visiteur = null

Quand User B (visitor) consulte :
  → Il voit le vrai username de User A
  → Il sait à qui il parle
```

---

## 🗄️ Index MongoDB (critiques pour la perf)

```javascript
// messages
db.messages.createIndex({ conversationId: 1, createdAt: -1 })

// conversations
db.conversations.createIndex({ linkOwner: 1, visitor: 1 }, { unique: true })
db.conversations.createIndex({ linkOwner: 1, updatedAt: -1 })
db.conversations.createIndex({ visitor: 1, updatedAt: -1 })
```

---

## 🔐 Sécurité

- ✅ JWT access (15min) + refresh (30j)
- ✅ bcrypt rounds=12
- ✅ Helmet (headers sécurisés)
- ✅ Rate limiting global (200/15min) + auth (20/15min)
- ✅ Validation Joi sur toutes les entrées
- ✅ senderId masqué pour le propriétaire du lien
- ✅ Vérification appartenance conversation avant chaque accès

---

## 📈 Scalabilité (~1000 users)

- Socket.IO rooms (pas de broadcast global)
- Pagination curseur (pas de skip/offset)
- Index MongoDB optimisés
- Pool MongoDB (maxPoolSize: 20)
- Reconnexion automatique WebSocket

---

## 🚀 Déploiement recommandé

| Composant | Service |
|---|---|
| Backend | Railway / Render / VPS |
| MongoDB | Atlas Free Tier → M10 si scale |
| Redis (optionnel) | Upstash Free |

```bash
# Production
NODE_ENV=production npm start
```

---

## 📦 Stack complète

| Layer | Tech |
|---|---|
| Frontend | Flutter + Riverpod + GoRouter |
| Backend | Node.js + Express + Socket.IO |
| Database | MongoDB (Mongoose) |
| Auth | JWT (access + refresh) |
| Security | bcrypt + Helmet + Joi + Rate limit |
| Real-time | Socket.IO (WebSocket) |
| i18n | FR + EN (ARB) |
| Theme | Light / Dark (Material 3) |
