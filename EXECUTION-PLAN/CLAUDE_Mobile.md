# CLAUDE.md — pickleball-mobile (React Native)

> Copy file này vào root của repo `pickleball-mobile` với tên `CLAUDE.md`

---

## Project Overview

**pickleball-mobile** là React Native app (Expo) cho iOS và Android.
- **Stack:** React Native · Expo SDK 51+ · TypeScript · NativeWind (TailwindCSS) · Zustand · React Query
- **Navigation:** Expo Router (file-based routing)
- **Auth Storage:** expo-secure-store (không localStorage)

## Tài Liệu Tham Khảo
→ `Documents/SCREEN-INVENTORY/Mobile_Screen_Inventory.md`
→ `Documents/API-CONTRACT/` cho API schema
→ `Documents/REALTIME/SignalR_Contracts.md` cho SignalR events

## Build & Run

```bash
npm install
cp .env.example .env
# Set EXPO_PUBLIC_API_URL=https://api.pickleballapp.com/api

npx expo start          # Development server
npx expo run:ios        # iOS simulator (cần Xcode)
npx expo run:android    # Android emulator (cần Android Studio)
npx expo start --go     # Expo Go app (scan QR)
```

## Project Structure

```
app/                   # Expo Router pages
├── (auth)/            # Auth stack (login, register...)
│   ├── login.tsx
│   ├── register.tsx
│   └── verify-email.tsx
├── (tabs)/            # Bottom tab navigator
│   ├── index.tsx      # Home
│   ├── tournaments.tsx
│   ├── community.tsx  # Phase 2
│   ├── chat.tsx       # Phase 2
│   └── profile.tsx
└── tournament/
    └── [id].tsx       # Tournament detail

src/
├── api/               # Same pattern as web
├── components/
│   ├── ui/            # RN-specific (TouchableOpacity, not button)
│   └── common/
├── features/
├── hooks/
├── stores/            # Zustand
└── types/
```

## Rules — PHẢI tuân thủ

### Platform Differences vs Web
- `Button` → `TouchableOpacity` hoặc `Pressable`
- `div` → `View`, `p` → `Text`, `img` → `Image`
- Styling: **NativeWind** (className) — không StyleSheet.create() cho UI thông thường
- Navigation: `router.push('/path')` (Expo Router), không `useNavigate`
- Storage: **expo-secure-store** cho tokens (không localStorage/AsyncStorage cho secrets)
- Keyboard: luôn wrap form trong `KeyboardAvoidingView`

### Tokens & Auth
```typescript
// Lưu token
await SecureStore.setItemAsync('accessToken', token)
await SecureStore.setItemAsync('refreshToken', refreshToken)

// Đọc token
const token = await SecureStore.getItemAsync('accessToken')
```

### Images
- Upload: `expo-image-picker` → crop → gửi multipart form
- Display: `expo-image` (lazy loading, blur placeholder)

### Push Notification
```typescript
// Đăng ký nhận FCM token sau khi login
const token = await Notifications.getExpoPushTokenAsync()
await deviceApi.register(token.data, Platform.OS)
```

### Deep Links
- Scheme: `pickleballapp://`
- Expo Router tự handle với `app.config.ts` scheme setting
- Notification tap → `router.push(notification.data.screen)`

### Performance
- FlatList: luôn có `keyExtractor`, `getItemLayout` nếu fixed height
- Images: dùng `expo-image` (caching built-in)
- Animations: `react-native-reanimated` (không Animated API cũ)

### Permissions
```typescript
// Location (hỏi khi cần, không hỏi khi start app)
const { status } = await Location.requestForegroundPermissionsAsync()

// Camera
const { status } = await ImagePicker.requestCameraPermissionsAsync()

// Notification
const { status } = await Notifications.requestPermissionsAsync()
```

## Build Verify
```bash
npx tsc --noEmit    # 0 TypeScript errors
npx expo start      # App loads without crash
```

## EAS Build (Production)
```bash
# Install EAS CLI
npm install -g eas-cli

# Build APK (Android)
eas build --platform android --profile preview

# Build IPA (iOS)
eas build --platform ios --profile preview

# Submit to stores
eas submit --platform android
eas submit --platform ios
```
