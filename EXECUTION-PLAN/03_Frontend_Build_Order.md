# Frontend Build Order — Thứ Tự Build FE Web

**Verify sau mỗi bước: `npm run build` — 0 errors**

---

## Bước 1: Foundation

### 1.1 — Types (Global)
```
src/types/index.ts
  - User, UserProfile
  - Tournament, TournamentStatus
  - Participant, ParticipantStatus
  - Match, MatchScore, Standings
  - Notification, NotificationType
  - ApiResponse<T>, PaginationMeta
  - ChatRoom, Message
```

### 1.2 — API Layer
```
src/api/axios.ts                 (instance + interceptors: attach token + auto-refresh 401)
src/api/auth.api.ts              (register, login, social, refresh, changePassword, verify)
src/api/user.api.ts              (profile, avatar, follow, tournaments)
src/api/tournament.api.ts        (CRUD, status, banner)
src/api/participant.api.ts       (invite, request, approve, teams, groups)
src/api/match.api.ts             (score, standings, results)
src/api/notification.api.ts      (list, markRead, registerDevice)
src/api/community.api.ts         (Phase 2)
src/api/chat.api.ts              (Phase 2)
```

### 1.3 — Zustand Stores
```
src/stores/auth.store.ts          (accessToken, refreshToken, user, isAuthenticated)
src/stores/notification.store.ts  (unreadCount, addNotification)
src/stores/signalr.store.ts       (connections map)
```

### 1.4 — Utilities
```
src/lib/cn.ts                (clsx + tailwind-merge)
src/lib/formatDate.ts        (date-fns wrappers)
src/lib/formatScore.ts       (11-7 format)
src/lib/queryKeys.ts         (React Query key factories)
```

### 1.5 — Router Setup
```
src/routes/AppRouter.tsx          (BrowserRouter + routes)
src/routes/ProtectedRoute.tsx     (redirect nếu chưa login)
src/routes/GuestRoute.tsx         (redirect nếu đã login)
```

✅ `npm run build` — 0 errors

---

## Bước 2: UI Component Library

### 2.1 — Primitive UI (src/components/ui/)
```
Button.tsx          (variants: primary, secondary, ghost, danger; sizes: sm, md, lg)
Input.tsx           (label, error message, disabled state)
Textarea.tsx
Select.tsx
Modal.tsx           (portal, backdrop, close on Escape)
Badge.tsx           (status colors)
Spinner.tsx         (loading indicator)
Card.tsx
Avatar.tsx          (fallback initials)
Toast.tsx           (dùng Sonner)
ConfirmDialog.tsx   (confirm/cancel)
Pagination.tsx
EmptyState.tsx
ErrorBoundary.tsx
```

### 2.2 — Layout (src/components/layout/)
```
PageLayout.tsx      (sidebar + main content)
Header.tsx          (logo, nav, notification bell, user menu)
Sidebar.tsx         (nav links, collapse)
BottomNav.tsx       (mobile bottom nav)
AuthLayout.tsx      (centered card for auth pages)
```

### 2.3 — Common Domain Components
```
TournamentCard.tsx        (name, type, date, slots X/Y, status badge)
UserAvatar.tsx            (avatar + name)
StatusBadge.tsx           (tournament/match status với màu tương ứng)
ScoreDisplay.tsx          (11-7, 9-11, 11-8 format)
NotificationBadge.tsx     (số unread)
CapacityBar.tsx           (X/Y progress bar)
InfiniteScrollList.tsx    (wrapper tự động fetch thêm)
```

✅ `npm run build` — 0 errors

---

## Bước 3: Auth Feature

### 3.1 — Hooks
```
src/features/auth/hooks/useLogin.ts          (useMutation → authApi.login)
src/features/auth/hooks/useRegister.ts
src/features/auth/hooks/useVerifyEmail.ts
src/features/auth/hooks/useForgotPassword.ts
src/features/auth/hooks/useChangePassword.ts
```

### 3.2 — Pages
```
src/features/auth/pages/LoginPage.tsx
  - Form: email + password
  - Google/Apple/Facebook buttons
  - Error display
  - Redirect sau login

src/features/auth/pages/RegisterPage.tsx
  - Form với Zod validation
  - PasswordStrengthMeter

src/features/auth/pages/VerifyEmailPage.tsx
  - OTP6Input (6 ô tự động focus next)
  - Resend button + 60s countdown

src/features/auth/pages/ForgotPasswordPage.tsx
src/features/auth/pages/ResetPasswordPage.tsx
```

✅ Test: register → verify email → login → nhận JWT

---

## Bước 4: Tournament List & Detail

### 4.1
```
src/features/tournament/hooks/useTournaments.ts   (useInfiniteQuery với filter)
src/features/tournament/hooks/useTournamentDetail.ts
src/features/tournament/hooks/useJoinRequest.ts   (POST /request)
```

### 4.2
```
src/features/tournament/pages/TournamentListPage.tsx
  - SearchBar + FilterBar (status chips, type chips)
  - InfiniteScrollList<TournamentCard>
  - FloatingActionButton "+" → /tournaments/create

src/features/tournament/pages/TournamentDetailPage.tsx
  - Banner, header info
  - TabBar: Overview | Participants | Schedule | Standings | Results
  - ActionBar (role-based):
    Guest → "Xin tham gia" / "Đang chờ"
    Creator → "Quản lý giải" button
```

✅ Test: vào list → xem detail → xin tham gia

---

## Bước 5: Tournament Create & Manage (Creator)

### 5.1
```
src/features/tournament/pages/CreateTournamentPage.tsx
  - MultiStepForm (3 bước + progress indicator)
  - Step 1: name, type, numGroups (visual selector với bracket preview)
  - Step 2: scoringFormat
  - Step 3: date, location, bannerUrl (ImageUpload)

src/features/tournament/pages/TournamentManagePage.tsx
  - StatusStepper
  - TabBar:
    RequestsTab: FlatList requests, approve/reject buttons
    ParticipantsTab: list + remove
    TeamsTab (doubles): DragDropPairing
    GroupsTab: DragDropGroups + RandomButton + preview
    ScheduleTab: danh sách matches
```

✅ Test: create → publish → receive request → approve → xếp bảng

---

## Bước 6: Match & Bracket

### 6.1
```
src/features/match/hooks/useMatchSchedule.ts
src/features/match/hooks/useSubmitScore.ts
src/features/match/hooks/useStandings.ts
src/features/match/hooks/useTournamentHub.ts     (SignalR)

src/features/match/pages/BracketViewPage.tsx
  - Tabs per group
  - Round Robin grid
  - Click match → ScoreModal (Creator) hoặc ScoreDisplay

src/features/match/components/ScoreInputModal.tsx
  - Player1 / Player2 columns
  - Set rows (tự add khi cần)
  - Auto-detect winner
  - Disable submit nếu score invalid

src/features/match/components/StandingsTable.tsx
  - W, L, PF, PA, Diff, Rank
  - Real-time update via SignalR
```

✅ Test: xem bracket → nhập điểm → BXH cập nhật real-time

---

## Bước 7: Profile

```
src/features/profile/hooks/useMyProfile.ts
src/features/profile/hooks/useUserProfile.ts
src/features/profile/hooks/useFollowActions.ts

src/features/profile/pages/MyProfilePage.tsx
  - AvatarSection + edit button
  - StatsBar (W/L, tournaments, followers/following)
  - TournamentHistoryList (filter tabs)
  - FollowersTab / FollowingTab

src/features/profile/pages/EditProfilePage.tsx
  - AvatarUpload + react-image-crop
  - Form fields
  - SkillLevelSlider

src/features/profile/pages/UserProfilePage.tsx
  - FollowButton (optimistic update)
  - H2H stats (nếu có)
```

---

## Bước 8: Notification

```
src/features/notification/hooks/useNotifications.ts
src/features/notification/hooks/useNotificationHub.ts   (SignalR)

src/features/notification/pages/NotificationListPage.tsx
  - FilterTabs (All | Unread | Tournament | Social)
  - NotificationItem với icon theo type
  - MarkAllReadButton
  - Real-time prepend mới
```

---

## Bước 9: Home Dashboard

```
src/features/home/pages/HomePage.tsx
  - UpcomingMatchCard (trận đấu tiếp theo)
  - MyTournamentsWidget (horizontal scroll)
  - RecentNotificationsWidget
```

---

## Bước 10: Community & Chat (Phase 2)

```
src/features/community/...
src/features/chat/...
```

---

## Final Verify

```bash
npm run build                  # 0 TypeScript errors, 0 warnings (important)
npm run lint                   # 0 ESLint errors

# Manual test checklist:
# ✅ Login → redirect /home
# ✅ Tournament list load
# ✅ Create tournament (3 steps)
# ✅ Score input + BXH update
# ✅ Notification bell badge
# ✅ SignalR connects (check Network tab → WS)
```
