# API Development Checker — AppPickleball Frontend

> **Cập nhật lần cuối:** 2026-03-13  
> **BE URL (dev):** `http://localhost:5283/api`

## Tổng quan

| Module | Tổng | ✅ Đã ghép FE + trang | ⚠️ Hook có, trang chưa ghép | ⏳ BE chưa có |
|--------|:----:|:---------------------:|:-----------------------------:|:------------:|
| 01 Auth | 11 | 2 (login, register) | 8 | 0 |
| 02 User & Profile | 10 | 0 | 9 | 1 |
| 03 Tournament Management | 7 | 6 | 0 | 1 |
| 04 Participant Management | 7 | 3 | 3 | 1 |
| 05 Match & Scoring | 6 | 3 | 3 | 0 |
| 06 Community Game | 8 | 0 | 0 | 8 |
| 07 Chat & Notification | 7 | 0 | 0 | 7 |
| **TỔNG** | **56** | **14** | **23** | **18** |

> **Ghi chú cột**: ✅ = hook created + wired to a real page UI | ⚠️ = service + hook created, nhưng page vẫn còn dùng mock/chưa kết nối | ⏳ = BE chưa implement endpoint

---

## Module 01: Authentication (11 endpoints)

| # | Method | Endpoint | Status | Màn hình | Hook |
|---|--------|----------|:------:|----------|------|
| 1.1 | POST | `/auth/register` | ✅ | RegisterPage | `useRegister` |
| 1.2 | POST | `/auth/login` | ✅ | LoginPage | `useLogin` |
| 1.4 | POST | `/auth/refresh` | ✅ | Auto (axios interceptor) | — |
| 1.5 | PUT | `/auth/password` | ⚠️ | ProfilePage (chưa wire) | `useChangePassword` |
| 1.6 | POST | `/auth/send-verification` | ⚠️ | ProfilePage (chưa wire) | `useSendVerification` |
| 1.7 | POST | `/auth/verify-email` | ⚠️ | ProfilePage (chưa wire) | `useVerifyEmail` |
| 1.8 | POST | `/auth/forgot-password` | ⚠️ | Chưa có trang | `useForgotPassword` |
| 1.9 | POST | `/auth/reset-password` | ⚠️ | Chưa có trang | `useResetPassword` |
| 1.10 | POST | `/auth/google-login` | ⚠️ | LoginPage (UI có, chờ OAuth SDK) | `useGoogleLogin` |
| 1.11 | POST | `/auth/facebook-login` | ⚠️ | LoginPage (UI có, chờ OAuth SDK) | `useFacebookLogin` |

> **Ghi chú SSO:** Button Google + Facebook đã có trên LoginPage. Cần tích hợp Google OAuth SDK và Facebook Login SDK để lấy `idToken`/`accessToken` rồi gọi hook.

---

## Module 02: User & Profile (9/10 → 1 BE chưa có)

| # | Method | Endpoint | Status | Màn hình | Hook |
|---|--------|----------|:------:|----------|------|
| 2.1 | GET | `/users/me` | ⚠️ | ProfilePage (chưa wire) | `useMyProfile` |
| 2.2 | PUT | `/users/me` | ⚠️ | ProfilePage (chưa wire) | `useUpdateProfile` |
| 2.3 | POST | `/users/me/avatar` | ⏳ | ProfilePage | — | **BE chưa có** |
| 2.4 | GET | `/users/me/tournaments` | ⚠️ | ProfilePage (chưa wire) | `useMyTournaments` |
| 2.5 | GET | `/users/me/following` | ⚠️ | ProfilePage (chưa wire) | `useFollowing` |
| 2.6 | GET | `/users/me/followers` | ⚠️ | ProfilePage (chưa wire) | `useFollowers` |
| 2.7 | POST | `/users/:id/follow` | ⚠️ | ProfilePage (chưa wire) | `useFollow` |
| 2.8 | DELETE | `/users/:id/follow` | ⚠️ | ProfilePage (chưa wire) | `useUnfollow` |
| 2.9 | GET | `/users/:id` | ⚠️ | ProfilePage (chưa wire) | `useUserProfile` |
| 2.10 | GET | `/users/:id/matches` | ⚠️ | ProfilePage (chưa wire) | `useUserMatches` |

---

## Module 03: Tournament Management (6/7 ✅ → 1 BE chưa có)

| # | Method | Endpoint | Status | Màn hình | Hook |
|---|--------|----------|:------:|----------|------|
| 3.1 | GET | `/tournaments` | ✅ | TournamentsPage | `useTournaments` |
| 3.2 | POST | `/tournaments` | ⚠️ | CreateTournamentPage (chưa wire) | `useCreateTournament` |
| 3.3 | GET | `/tournaments/:id` | ✅ | TournamentDetailPage | `useTournament` |
| 3.4 | PUT | `/tournaments/:id` | ⚠️ | TournamentDetailPage (chưa wire) | `useUpdateTournament` |
| 3.5 | DELETE | `/tournaments/:id` | ⚠️ | TournamentDetailPage (chưa wire) | `useCancelTournament` |
| 3.6 | PUT | `/tournaments/:id/status` | ⚠️ | TournamentDetailPage (chưa wire) | `useUpdateTournamentStatus` |
| 3.7 | POST | `/tournaments/:id/banner` | ⏳ | CreateTournamentPage | — | **BE chưa có** |

---

## Module 04: Participant Management (6/7 → 1 BE chưa có)

| # | Method | Endpoint | Status | Màn hình | Hook |
|---|--------|----------|:------:|----------|------|
| 4.1 | POST | `/tournaments/:id/invite` | ⚠️ | TournamentDetailPage (chưa wire) | `useInviteParticipants` |
| 4.2 | POST | `/tournaments/:id/join` | ✅ | TournamentDetailPage | `useRequestJoin` |
| 4.3 | PUT | `/tournaments/:id/participants/:pid/respond` | ✅ | TournamentDetailPage | `useRespondToRequest` |
| 4.4 | GET | `/tournaments/:id/participants` | ✅ | TournamentDetailPage | `useParticipants` |
| 4.5 | DELETE | `/tournaments/:id/participants/:uid` | ⏳ | TournamentDetailPage | — | **BE chưa có** |
| 4.6 | POST | `/tournaments/:id/teams` | ⚠️ | TournamentDetailPage (chưa wire) | `useCreateTeams` |
| 4.7 | POST | `/tournaments/:id/groups` | ⚠️ | TournamentDetailPage (chưa wire) | `useCreateGroups` |

---

## Module 05: Match & Scoring (6/6 ✅)

| # | Method | Endpoint | Status | Màn hình | Hook |
|---|--------|----------|:------:|----------|------|
| 5.1 | GET | `/tournaments/:id/matches` | ✅ | TournamentDetailPage | `useMatches` |
| 5.2 | GET | `/tournaments/:id/draw` | ⚠️ | TournamentDetailPage (chưa wire) | `useDraw` |
| 5.3 | POST | `/matches/:id/score` | ⚠️ | TournamentDetailPage (chưa wire) | `useSubmitScore` |
| 5.4 | PUT | `/matches/:id/score` | ⚠️ | TournamentDetailPage (chưa wire) | `useUpdateScore` |
| 5.5 | GET | `/tournaments/:id/groups/:gid/standings` | ✅ | TournamentDetailPage | `useGroupStandings` |
| 5.6 | GET | `/tournaments/:id/results` | ✅ | TournamentDetailPage | `useTournamentResults` |

---

## Module 06: Community Game (0/8 ⏳ — BE chưa có)

> ⚠️ Không có `CommunityController` trong BE. Types đã tạo sẵn trong `src/types/future.types.ts`.

| # | Endpoint | Màn hình dự kiến |
|---|----------|-----------------|
| 6.1–6.8 | `/community/*` | CommunityPage, GameDetailPage |

---

## Module 07: Chat & Notification (0/7 ⏳ — BE chưa có)

> ⚠️ Không có `ChatController`/`NotificationController`. Types đã tạo sẵn trong `src/types/future.types.ts`.

| # | Endpoint | Màn hình dự kiến |
|---|----------|-----------------|
| 7.1–7.4 | `/chats/*` | ChatPage, ChatRoomPage |
| 7.5–7.7 | `/notifications/*` | NotificationsPage |

---

## Files FE đã tạo/cập nhật

| File | Loại | Mô tả |
|------|------|-------|
| `src/pages/LoginPage.tsx` | Page | ✅ Real API (useLogin), Facebook button |
| `src/pages/RegisterPage.tsx` | Page | ✅ Real API (useRegister) |
| `src/pages/TournamentsPage.tsx` | Page | ✅ Real API (useTournaments, filter, loading state) |
| `src/pages/TournamentDetailPage.tsx` | Page | ✅ Real API (useTournament, useParticipants, useMatches, useGroupStandings, useTournamentResults, useRequestJoin, useRespondToRequest) |
| `src/components/ThemeToggle.tsx` | Component | Dark mode toggle (icon + full variant) |
| `src/components/layout/Header.tsx` | Layout | ThemeToggle icon, dark mode CSS vars |
| `src/components/layout/Sidebar.tsx` | Layout | ThemeToggle full row, dark mode CSS vars |
| `src/types/common.types.ts` | Types | ApiResponse, PagedResponse |
| `src/types/auth.types.ts` | Types | Auth requests/responses |
| `src/types/user.types.ts` | Types | User profiles, follows, history |
| `src/types/tournament.types.ts` | Types | Tournament, TournamentDetail, Groups |
| `src/types/participant.types.ts` | Types | Participants, Teams, Groups |
| `src/types/match.types.ts` | Types | Matches, Scores, Standings, Results |
| `src/types/future.types.ts` | Types | ⚠️ Community, Chat, Notification (BE chưa có) |
| `src/api/auth.service.ts` | Service | 11 auth endpoints |
| `src/api/user.service.ts` | Service | 9 user endpoints |
| `src/api/tournament.service.ts` | Service | 6 tournament endpoints |
| `src/api/participant.service.ts` | Service | 6 participant endpoints |
| `src/api/match.service.ts` | Service | 6 match endpoints |
| `src/hooks/useAuth.ts` | Hooks | login, register, SSO, password, verification |
| `src/hooks/useUser.ts` | Hooks | profile, update, follow/unfollow, history |
| `src/hooks/useTournament.ts` | Hooks | list, detail, create, update, cancel, status |
| `src/hooks/useParticipant.ts` | Hooks | list, join, invite, respond, groups, teams |
| `src/hooks/useMatch.ts` | Hooks | matches, draw, score, standings, results |
| `.env.development` | Config | VITE_API_BASE_URL=http://localhost:5283/api |
| `.env.production` | Config | VITE_API_BASE_URL=https://api.pickleball-app.com/api |

---

## Các trang cần wire thêm (ưu tiên cao)

| Trang | APIs cần wire |
|-------|--------------|
| **ProfilePage** | `useMyProfile`, `useUpdateProfile`, `useMyTournaments`, `useFollowing`, `useFollowers`, `useFollow`, `useUnfollow` |
| **CreateTournamentPage** | `useCreateTournament` |
| **TournamentDetailPage (admin)** | `useUpdateTournament`, `useCancelTournament`, `useUpdateTournamentStatus`, `useCreateGroups`, `useCreateTeams`, `useInviteParticipants`, `useSubmitScore`, `useUpdateScore` |
| **Homepage** | `useTournaments` (featured) |
