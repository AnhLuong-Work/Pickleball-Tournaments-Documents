# Mobile Screen Inventory — React Native (Expo + TypeScript)

**Phiên bản:** 1.0 | **Ngày:** Tháng 3, 2026
**Navigation:** React Navigation v6 (Stack + Bottom Tab) | **State:** Zustand

---

## Navigation Structure

```
RootNavigator (Stack)
├── AuthStack (khi chưa login)
│   ├── LoginScreen
│   ├── RegisterScreen
│   ├── VerifyEmailScreen
│   ├── ForgotPasswordScreen
│   └── ResetPasswordScreen
│
└── MainStack (khi đã login)
    ├── BottomTabNavigator
    │   ├── Tab: Home         → HomeScreen
    │   ├── Tab: Tournaments  → TournamentListScreen
    │   ├── Tab: Community    → CommunityLobbyScreen (Phase 2)
    │   ├── Tab: Chat         → ChatListScreen (Phase 2)
    │   └── Tab: Profile      → MyProfileScreen
    │
    └── ModalStack (push trên BottomTab)
        ├── TournamentDetailScreen
        ├── BracketViewScreen
        ├── TournamentManageScreen
        ├── ScoreInputScreen
        ├── CreateTournamentScreen
        ├── GameDetailScreen
        ├── CreateGameScreen
        ├── ChatDetailScreen
        ├── NotificationListScreen
        ├── UserProfileScreen
        └── EditProfileScreen
```

---

## Auth Stack

### M-S01 — LoginScreen
- **Platform:** iOS + Android
- **Components:** EmailInput, PasswordInput, LoginButton, GoogleSignInButton, AppleSignInButton (iOS only), FacebookSignInButton, ForgotPasswordLink
- **Gestures:** Keyboard dismiss on scroll
- **Biometric:** Nếu đã login trước → offer Face ID / Fingerprint

### M-S02 — RegisterScreen
- **Components:** Tương tự Web S02
- **Note:** KeyboardAvoidingView bắt buộc

### M-S03 — VerifyEmailScreen
- **Components:** OTP6Input (auto-focus next input), ResendButton, CountdownTimer
- **Note:** Paste OTP từ clipboard → auto-fill

### M-S04 — ForgotPasswordScreen
- **Components:** EmailInput, SubmitButton

### M-S05 — ResetPasswordScreen
- **Components:** NewPasswordInput, ConfirmPasswordInput, SubmitButton

---

## Main App — Bottom Tab Screens

### M-S06 — HomeScreen
- **Tab:** Home (icon: home)
- **Components:**
  - `MyUpcomingMatchCard` — trận đấu tiếp theo của tôi (highlight)
  - `MyTournamentsList` — horizontal scroll, giải đang tham gia
  - `CommunityGamesNearby` — game gần vị trí (yêu cầu location permission)
  - `RecentNotificationsBadge`
- **Permissions:** Location (cho CommunityGamesNearby)

### M-S07 — TournamentListScreen
- **Tab:** Tournaments (icon: trophy)
- **Components:**
  - SearchBar (top)
  - FilterChips (All / Open / In Progress / Completed, Singles / Doubles)
  - FlatList TournamentCard (infinite scroll)
  - FloatingActionButton "+" → CreateTournamentScreen
- **Pull-to-refresh:** có

### M-S13 — CommunityLobbyScreen (Phase 2)
- **Tab:** Community (icon: people)
- **Components:**
  - MapView / ListView toggle
  - DateFilter, SkillLevelFilter
  - GameCard list + MapMarkers
  - FAB "Tạo game" → CreateGameScreen

### M-S16 — ChatListScreen (Phase 2)
- **Tab:** Chat (icon: chat-bubble)
- **Badge:** số unread conversations
- **Components:** ConversationList (swipe left to mute/delete)
- **Real-time:** SignalR cập nhật lastMessage, unread count

### M-S18 — MyProfileScreen
- **Tab:** Profile (icon: person)
- **Components:**
  - AvatarHeader (tap để edit)
  - StatsRow
  - SegmentedControl: [Giải đấu | Followers | Following]
  - SettingsButton (top right) → SettingsScreen

---

## Modal Stack Screens

### M-S08 — TournamentDetailScreen
- **Access:** Authenticated
- **Components:**
  - ScrollView với TournamentBanner
  - TabView: [Info | Participants | Schedule | Standings | Results]
  - StickyActionBar bottom: role-based CTA
- **Real-time:** SignalR TournamentHub cho live scores

### M-S09 — BracketViewScreen
- **Components:** Pinch-to-zoom SVG bracket, GroupSelector tabs
- **Note:** Sử dụng `react-native-svg` hoặc WebView với D3.js

### M-S10 — CreateTournamentScreen
- **Components:**
  - MultiStepForm (3 bước, progress bar)
  - ImagePicker cho banner
  - DateTimePicker native
- **API calls:** `POST /tournaments`, `POST /tournaments/:id/banner`

### M-S11 — TournamentManageScreen (Creator)
- **Components:**
  - TabView: [Requests | Participants | Teams | Groups | Schedule]
  - Pull-to-refresh trên mỗi tab
  - SwipeableRow: approve/reject trong RequestsTab

### M-S12 — ScoreInputScreen (Creator)
- **Components:**
  - MatchPicker (dropdown)
  - ScoreGrid: số lớn dễ tap
  - +/- buttons hoặc keyboard input
  - Real-time winner detection
- **UX Note:** Input số lớn, dễ dùng khi đang đứng ở sân

### M-S14 — CreateGameScreen (Phase 2)
- **Components:** Form, MapView picker (react-native-maps), DateTimePicker, Slider cho maxPlayers

### M-S15 — GameDetailScreen (Phase 2)
- **Components:**
  - StaticMapView (preview vị trí)
  - ParticipantAvatarRow
  - WaitlistInfo (nếu đầy)
  - ChatButton → ChatDetailScreen

### M-S17 — ChatDetailScreen (Phase 2)
- **Components:**
  - FlatList inverted (mới nhất ở dưới)
  - TypingBubble
  - MessageInput + CameraButton + SendButton
  - ImageMessage (Cloudinary URL)
- **Performance:** VirtualizedList, lazy load ảnh

### M-S19 — EditProfileScreen
- **Components:**
  - AvatarPicker (camera hoặc gallery, crop với react-native-image-crop-picker)
  - Form fields
  - SkillLevelSlider (1.0–5.0, step 0.5)

### M-S20 — UserProfileScreen
- **Components:** ProfileHeader, FollowButton, StatsRow, MatchHistoryList, H2H Stats (nếu cả 2 có lịch sử đấu nhau)

### M-S21 — NotificationListScreen
- **Components:**
  - FilterTabs (scroll horizontal)
  - SwipeableNotificationItem (swipe to mark read)
  - Deep link handler khi tap
- **Real-time:** SignalR, cập nhật badge trên app icon (Expo Notifications)

---

## Push Notification Deep Link Map

| Screen | Deep link URL scheme |
|--------|---------------------|
| TournamentDetailScreen | `pickleballapp://tournament/:id` |
| ChatDetailScreen | `pickleballapp://chat/:id` |
| NotificationListScreen | `pickleballapp://notifications` |
| GameDetailScreen | `pickleballapp://game/:id` |
| UserProfileScreen | `pickleballapp://profile/:id` |

---

## Permissions Cần Xin

| Permission | Màn hình | Lý do |
|-----------|---------|-------|
| Camera | EditProfileScreen, ChatDetailScreen | Chụp ảnh avatar / gửi ảnh |
| Photo Library | EditProfileScreen, ChatDetailScreen | Chọn ảnh |
| Location | HomeScreen, CommunityLobbyScreen | Tìm game gần đây |
| Push Notification | App startup (sau login) | Nhận FCM |
| Face ID / Fingerprint | LoginScreen | Biometric login |

---

## Offline Support Notes

- Danh sách giải đấu: cache 5 phút (React Query staleTime)
- Chat messages: queue offline, gửi khi reconnect
- Score input: block nếu offline (cần real-time confirm)
- Profile: cache indefinitely, refetch on focus
