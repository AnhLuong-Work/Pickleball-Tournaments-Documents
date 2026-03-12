# Web Screen Inventory — React App (Vite + TypeScript + TailwindCSS)

**Phiên bản:** 1.0 | **Ngày:** Tháng 3, 2026
**Router:** React Router v6 | **State:** Zustand | **API:** Axios + React Query

---

## Tổng Quan Cấu Trúc Route

```
/                          → Redirect (auth check)
├── /auth/
│   ├── login              → LoginScreen
│   ├── register           → RegisterScreen
│   ├── verify-email       → VerifyEmailScreen
│   ├── forgot-password    → ForgotPasswordScreen
│   └── reset-password     → ResetPasswordScreen
│
├── /tournaments/          → TournamentListScreen (Public browse)
│   ├── :id               → TournamentDetailScreen
│   └── :id/bracket       → BracketViewScreen
│
├── (Protected — cần login)
│   ├── /home             → HomeScreen (Dashboard)
│   ├── /tournaments/
│   │   └── create        → CreateTournamentScreen
│   │   └── :id/edit      → EditTournamentScreen
│   │   └── :id/manage    → TournamentManageScreen (Creator only)
│   │   └── :id/score     → ScoreInputScreen (Creator only)
│   │
│   ├── /community/
│   │   ├── lobby         → CommunityLobbyScreen
│   │   ├── create        → CreateGameScreen
│   │   └── :id           → GameDetailScreen
│   │
│   ├── /chat/
│   │   ├── index         → ChatListScreen
│   │   └── :id           → ChatDetailScreen
│   │
│   ├── /notifications    → NotificationListScreen
│   │
│   └── /profile/
│       ├── me            → MyProfileScreen
│       ├── me/edit       → EditProfileScreen
│       └── :id           → UserProfileScreen
```

---

## Chi Tiết Từng Màn Hình

### AUTH SCREENS

#### S01 — LoginScreen
- **Route:** `/auth/login`
- **Access:** Guest (redirect nếu đã login)
- **Components:** EmailInput, PasswordInput, LoginButton, SocialLoginButtons (Google/Apple/Facebook), ForgotPasswordLink
- **API calls:** `POST /auth/login`, `POST /auth/social`
- **State:** form errors, loading, remember me
- **Navigate to:** `/home` (success), `/auth/verify-email` (email chưa verify)

#### S02 — RegisterScreen
- **Route:** `/auth/register`
- **Access:** Guest
- **Components:** NameInput, EmailInput, PasswordInput + ConfirmPassword, PasswordStrengthMeter, RegisterButton
- **API calls:** `POST /auth/register`
- **Validation:** real-time (name min 2 chars, email format, password strength)
- **Navigate to:** `/auth/verify-email?email=xxx`

#### S03 — VerifyEmailScreen
- **Route:** `/auth/verify-email`
- **Access:** Guest
- **Components:** OTP6Input (6 ô tự động focus), ResendOTPButton (countdown 60s), ChangeEmailLink
- **API calls:** `POST /auth/verify-email`, `POST /auth/send-verification`
- **Navigate to:** `/auth/login` (success)

#### S04 — ForgotPasswordScreen
- **Route:** `/auth/forgot-password`
- **Components:** EmailInput, SubmitButton
- **API calls:** `POST /auth/forgot-password`
- **Note:** Luôn hiện message thành công dù email có tồn tại hay không

#### S05 — ResetPasswordScreen
- **Route:** `/auth/reset-password?token=xxx`
- **Components:** NewPasswordInput, ConfirmPasswordInput, PasswordStrengthMeter
- **API calls:** `POST /auth/reset-password`
- **Navigate to:** `/auth/login` (success)

---

### MAIN APP SCREENS

#### S06 — HomeScreen (Dashboard)
- **Route:** `/home`
- **Access:** Authenticated
- **Layout:** Sidebar (desktop) / BottomNav (mobile-web)
- **Components:**
  - `MyTournamentsWidget` — giải đấu của tôi (đang tham gia, đang tạo)
  - `UpcomingMatchesWidget` — trận đấu sắp tới
  - `RecentNotificationsWidget` — 3 thông báo mới nhất
  - `CommunityGamesWidget` — game giao hữu gần đây
- **API calls:** `GET /users/me`, `GET /users/me/tournaments`, `GET /notifications?page=1&pageSize=3`

---

### TOURNAMENT SCREENS

#### S07 — TournamentListScreen
- **Route:** `/tournaments`
- **Access:** Public
- **Components:**
  - SearchBar, FilterBar (status, type: singles/doubles)
  - TournamentCard (name, type, date, location, slots X/Y, status badge)
  - Pagination / Infinite scroll
- **API calls:** `GET /tournaments?status=open&type=singles&page=1`
- **Note:** Sort mặc định: open trước, mới nhất trước

#### S08 — TournamentDetailScreen
- **Route:** `/tournaments/:id`
- **Access:** Authenticated
- **Components:**
  - TournamentHeader (banner, name, creator, status, date, location)
  - TabBar: [Tổng quan | Người tham gia | Lịch đấu | Kết quả | BXH]
  - ActionBar (role-based):
    - Guest/User: "Xin tham gia" | "Đang chờ duyệt" | "Đã xác nhận"
    - Creator: "Quản lý giải" button → `/tournaments/:id/manage`
- **API calls:** `GET /tournaments/:id`, `GET /tournaments/:id/participants`, `GET /tournaments/:id/matches`

#### S09 — BracketViewScreen
- **Route:** `/tournaments/:id/bracket`
- **Access:** Authenticated
- **Components:** InteractiveBracket (SVG/canvas, zoom/pan), GroupTabs
- **API calls:** `GET /tournaments/:id/draw`
- **Real-time:** SignalR subscribe `JoinTournament(id)` → listen `ScoreUpdated`, `StandingsUpdated`

#### S10 — CreateTournamentScreen
- **Route:** `/tournaments/create`
- **Access:** Authenticated
- **Components:**
  - Step 1: BasicInfoForm (name, type, description)
  - Step 2: SettingsForm (numGroups với visual preview, scoringFormat)
  - Step 3: DetailsForm (date, location, banner upload)
  - CapacityHint: "Giải này cần tối thiểu X người"
- **API calls:** `POST /tournaments`, `POST /tournaments/:id/banner`

#### S11 — TournamentManageScreen
- **Route:** `/tournaments/:id/manage`
- **Access:** Creator only
- **Components:**
  - StatusStepper (draft → open → ready → in_progress)
  - TabBar: [Yêu cầu tham gia | Người tham gia | Ghép đội (doubles) | Xếp bảng | Lịch đấu]
  - `RequestsTab`: danh sách request_pending, approve/reject buttons
  - `ParticipantsTab`: danh sách confirmed, remove button
  - `TeamsTab` (doubles only): drag-drop ghép cặp, random button
  - `GroupsTab`: drag-drop xếp bảng, random button, preview lịch đấu
- **API calls:** nhiều endpoints participant + team + group

#### S12 — ScoreInputScreen
- **Route:** `/tournaments/:id/score` hoặc modal trong ManageScreen
- **Access:** Creator only
- **Components:**
  - MatchSelector (chọn trận cần nhập)
  - ScoreForm: 2 columns (Player1 / Player2), rows theo từng set, auto-add set khi cần
  - WinnerIndicator: tự động highlight người thắng khi nhập
  - SubmitButton (disabled nếu score chưa hợp lệ)
- **API calls:** `POST /matches/:id/score`, `PUT /matches/:id/score`
- **Note:** Hiển thị realtime score đang được nhập

---

### COMMUNITY SCREENS

#### S13 — CommunityLobbyScreen
- **Route:** `/community/lobby`
- **Access:** Authenticated
- **Components:**
  - ViewToggle (List / Map)
  - FilterBar (date, skillLevel, hasSlots)
  - GameCard (title, date, location, skill, X/maxPlayers)
  - MapView (marker clustering)
- **API calls:** `GET /community/lobby`

#### S14 — CreateGameScreen
- **Route:** `/community/create`
- **Access:** Authenticated
- **Components:** GameForm (title, date/time picker, LocationPicker + Google Maps, maxPlayers slider, skillLevel select, description)
- **API calls:** `POST /community/games`

#### S15 — GameDetailScreen
- **Route:** `/community/:id`
- **Access:** Authenticated
- **Components:**
  - GameHeader (title, creator, date, location on map)
  - ParticipantsList (confirmed + waitlist)
  - ActionBar: "Tham gia" / "Rời game" / "Đã ở chờ (vị trí X)"
  - ChatPreview → link đến ChatDetailScreen
- **API calls:** `GET /community/games/:id`, `POST /community/games/:id/join`, `DELETE /community/games/:id/leave`

---

### CHAT SCREENS

#### S16 — ChatListScreen
- **Route:** `/chat`
- **Access:** Authenticated
- **Components:** ConversationList (avatar, name, lastMessage preview, time, unread badge)
- **API calls:** `GET /chats`
- **Real-time:** SignalR `MessageReceived` cập nhật preview + thứ tự

#### S17 — ChatDetailScreen
- **Route:** `/chat/:id`
- **Access:** Authenticated (Chat member)
- **Components:**
  - MessageList (bubble UI, lazy load cũ hơn khi scroll up)
  - TypingIndicator
  - MessageInput + SendButton + ImageAttachment
  - ReadReceipts
- **API calls:** `GET /chats/:id/messages`, `POST /chats/:id/messages`
- **Real-time:** SignalR events: `MessageReceived`, `UserTyping`, `UserStoppedTyping`, `MessageRead`

---

### PROFILE SCREENS

#### S18 — MyProfileScreen
- **Route:** `/profile/me`
- **Access:** Authenticated
- **Components:**
  - AvatarSection (avatar + edit button)
  - StatsBar (số giải tham gia, thắng/thua, followers/following)
  - TournamentHistoryList (filter: created/joined, ongoing/completed)
  - FollowersTab / FollowingTab
- **API calls:** `GET /users/me`, `GET /users/me/tournaments`, `GET /users/me/followers`, `GET /users/me/following`

#### S19 — EditProfileScreen
- **Route:** `/profile/me/edit`
- **Access:** Authenticated
- **Components:** AvatarUpload + crop, NameInput, BioTextarea, SkillLevelSlider (1.0–5.0), DominantHandSelect, PaddleTypeInput
- **API calls:** `PUT /users/me`, `POST /users/me/avatar`

#### S20 — UserProfileScreen
- **Route:** `/profile/:id`
- **Access:** Authenticated
- **Components:** ProfileHeader, StatsBar, MatchHistoryList, FollowButton (optimistic update)
- **API calls:** `GET /users/:id/profile`, `GET /users/:id/matches`, `POST /users/:id/follow`, `DELETE /users/:id/follow`

---

### NOTIFICATION SCREEN

#### S21 — NotificationListScreen
- **Route:** `/notifications`
- **Access:** Authenticated
- **Components:**
  - FilterTabs (All | Unread | Tournament | Social)
  - NotificationItem (icon by type, title, body, time, isRead state)
  - MarkAllReadButton
- **API calls:** `GET /notifications`, `PUT /notifications/read-all`
- **Real-time:** SignalR `NewNotification` push vào đầu list

---

## Component Library Shared

| Component | Dùng ở đâu |
|-----------|-----------|
| `TournamentCard` | S07, S06 |
| `UserAvatar` | Nhiều màn hình |
| `StatusBadge` | S07, S08, S11 |
| `ScoreDisplay` | S08, S09, S12 |
| `NotificationBadge` | Layout Header |
| `ConfirmDialog` | Rời giải, hủy game, xóa người |
| `InfiniteScrollList` | S07, S16, S21 |
| `MapPicker` | S14 |
| `BracketViewer` | S09 |
| `OTP6Input` | S03 |
