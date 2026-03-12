# API Development Checker — AppPickleball Backend

> **Cập nhật:** 2026-03-12
> **Phiên bản BE:** .NET 10 · Clean Architecture · CQRS/MediatR · PostgreSQL
> **Scope:** Phase 1 (Auth, User, Tournament, Participant, Match) — bỏ qua Chat, Communication, Notification

---

## Tóm Tắt Trạng Thái

| Module | Tổng Endpoints | ✅ Hoàn thành | ⚠️ Thiếu/Partial | ❌ Bỏ qua |
|--------|:--------------:|:-------------:|:-----------------:|:---------:|
| M1 — Auth | 11 | 11 | — | — |
| M2 — User Profile | 10 | 6 | 4 | — |
| M3 — Tournament | 7 | 7 | — | — |
| M4 — Participant | 5 | 4 | 1 (teams) | — |
| M5 — Match & Scoring | 5 | 5 | — | — |
| M6 — Community Game | — | — | — | Bỏ qua |
| M7 — Chat | — | — | — | Bỏ qua |
| M8 — Notification | — | — | — | Bỏ qua |
| **TỔNG** | **35** | **30** | **5** | |

---

## M1 — Authentication (`/api/auth`)

| # | Method | Route | Auth | Status | Handler | Ghi chú |
|---|--------|-------|:----:|--------|---------|---------|
| 1.1 | POST | `/auth/register` | ❌ | ✅ Done | `RegisterCommandHandler` | Hash password bcrypt, trả `AuthResponseDto` |
| 1.2 | POST | `/auth/login` | ❌ | ✅ Done | `LoginCommandHandler` | Validate credentials, refresh token rotation |
| 1.4 | POST | `/auth/refresh` | ❌ | ✅ Done | `RefreshTokenCommandHandler` | Token rotation + reuse detection |
| 1.5 | POST | `/auth/send-email-verification` | ✅ | ✅ Done | `SendEmailVerificationCommandHandler` | Gửi OTP 6 số qua email |
| 1.6 | POST | `/auth/verify-email` | ✅ | ✅ Done | `VerifyEmailCommandHandler` | Verify OTP hash |
| 1.7 | PUT | `/auth/password` | ✅ | ✅ Done | `ChangePasswordCommandHandler` | Validate old password |
| 1.8 | POST | `/auth/forgot-password` | ❌ | ✅ Done | `ForgotPasswordCommandHandler` | Gửi OTP 6 số qua email, không tiết lộ email tồn tại |
| 1.9 | POST | `/auth/reset-password` | ❌ | ✅ Done | `ResetPasswordCommandHandler` | Verify OTP, đặt lại password, xóa token |
| 1.10 | POST | `/auth/google-login` | ❌ | ✅ Done | `GoogleLoginCommandHandler` | Verify Google ID Token, Find/Create user, Link provider |
| 1.11 | POST | `/auth/facebook-login` | ❌ | ✅ Done | `FacebookLoginCommandHandler` | Graph API verify, Find/Create user, handle no-email case |

### Request/Response nhanh

```
POST /auth/register
  Body: { email, password, name }
  Response: 201 { user: UserTokenDto, tokens: { accessToken, refreshToken } }

POST /auth/login
  Body: { email, password }
  Response: 200 { user: UserTokenDto, tokens: { accessToken, refreshToken } }

POST /auth/refresh
  Body: { refreshToken }
  Response: 200 { tokens: { accessToken, refreshToken } }

PUT /auth/password  [Authorize]
  Body: { currentPassword, newPassword }
  Response: 200 { message }

POST /auth/send-email-verification  [Authorize]
  Body: {}
  Response: 200 { message }

POST /auth/verify-email  [Authorize]
  Body: { token }
  Response: 200 { message }

POST /auth/forgot-password
  Body: { email }
  Response: 200 { message, expiresInSeconds: 600 }
  // Luôn trả 200 dù email có tồn tại hay không (security)

POST /auth/reset-password
  Body: { email, otp, newPassword }
  Response: 200 { message }

POST /auth/google-login
  Body: { idToken: "eyJhbGciOiJSUzI1NiIs..." }
  Response: 200 { accessToken, refreshToken, expiresIn, user: UserTokenDto, isNewUser: bool }
  // idToken từ Google Sign-In SDK (Web GIS / Expo / Flutter)
  // isNewUser = true → redirect đến onboarding

POST /auth/facebook-login
  Body: { accessToken: "EAABwzLixFW8BO..." }
  Response: 200 { accessToken, refreshToken, expiresIn, user: UserTokenDto, isNewUser: bool }
  // accessToken từ Facebook SDK
  // Nếu không có email → email = "fb_{id}@facebook.placeholder"
```

---

## M2 — User Profile (`/api/users`)

| # | Method | Route | Auth | Status | Handler | Ghi chú |
|---|--------|-------|:----:|--------|---------|---------|
| 2.1 | GET | `/users/me` | ✅ | ✅ Done | `GetMyProfileQueryHandler` | Trả stats tổng hợp |
| 2.2 | PUT | `/users/me` | ✅ | ✅ Done | `UpdateProfileCommandHandler` | Partial update |
| 2.3 | POST | `/users/me/avatar` | ✅ | ⚠️ Thiếu | — | Cần implement file upload (IStorageService) |
| 2.4 | GET | `/users/me/tournaments` | ✅ | ⚠️ Thiếu | — | List giải đấu của user (chưa build query) |
| 2.5 | GET | `/users/me/following` | ✅ | ⚠️ Thiếu | — | List người đang follow (chưa build query) |
| 2.6 | GET | `/users/me/followers` | ✅ | ⚠️ Thiếu | — | List followers (chưa build query) |
| 2.7 | POST | `/users/:id/follow` | ✅ | ✅ Done | `FollowCommandHandler` | Validate không self-follow |
| 2.8 | DELETE | `/users/:id/follow` | ✅ | ✅ Done | `UnfollowCommandHandler` | |
| 2.9 | GET | `/users/:id` | ❌ | ✅ Done | `GetUserProfileQueryHandler` | Public profile + H2H stats + isFollowing |
| 2.10 | GET | `/users/:id/matches` | ❌ | ⚠️ Thiếu | — | Match history của user (chưa build query) |

### Request/Response nhanh

```
GET /users/me  [Authorize]
  Response: 200 { id, name, email, avatarUrl, skillLevel, ..., stats: { totalTournaments, wins, ... } }

PUT /users/me  [Authorize]
  Body: { name?, bio?, skillLevel?, dominantHand?, paddleType? }
  Response: 200 { updated profile }

GET /users/:id
  Response: 200 { ...publicProfile, stats, headToHead?, isFollowing?, isFollowedBy? }

POST /users/:id/follow  [Authorize]
  Response: 201 { message }

DELETE /users/:id/follow  [Authorize]
  Response: 200 { message }
```

---

## M3 — Tournament Management (`/api/tournaments`)

| # | Method | Route | Auth | Status | Handler | Ghi chú |
|---|--------|-------|:----:|--------|---------|---------|
| 3.1 | GET | `/tournaments` | ❌ | ✅ Done | `GetTournamentsQueryHandler` | Filter search/type/status, phân trang |
| 3.2 | POST | `/tournaments` | ✅ | ✅ Done | `CreateTournamentCommandHandler` | Yêu cầu EmailVerified |
| 3.3 | GET | `/tournaments/:id` | ❌ | ✅ Done | `GetTournamentByIdQueryHandler` | Full detail + groups nếu status >= Ready |
| 3.4 | PUT | `/tournaments/:id` | ✅ | ✅ Done | `UpdateTournamentCommandHandler` | Khóa type/numGroups nếu có participants |
| 3.5 | DELETE | `/tournaments/:id` | ✅ | ✅ Done | `CancelTournamentCommandHandler` | Status → Cancelled |
| 3.6 | PATCH | `/tournaments/:id/status` | ✅ | ✅ Done | `UpdateTournamentStatusCommandHandler` | State machine: Draft→Open→Ready→InProgress→Completed |
| 3.7 | POST | `/tournaments/:id/banner` | ✅ | ⚠️ Thiếu | — | File upload banner (cần IStorageService) |

### Request/Response nhanh

```
GET /tournaments?search=&type=Singles&status=Open&page=1&pageSize=10
  Response: 200 { items: TournamentDto[], total, page, pageSize }

POST /tournaments  [Authorize, EmailVerified]
  Body: { name, description?, type, numGroups, scoringFormat, date?, location? }
  Response: 201 { TournamentDto }

GET /tournaments/:id
  Response: 200 { TournamentDetailDto } // groups[] chỉ hiện nếu status >= Ready

PUT /tournaments/:id  [Authorize, Creator]
  Body: { name?, description?, numGroups?, scoringFormat?, date?, location? }
  Response: 200 { TournamentDetailDto }

PATCH /tournaments/:id/status  [Authorize, Creator]
  Body: { status: "Open" | "Ready" | "InProgress" | "Completed" | "Cancelled", reason? }
  Response: 200 { message }
```

### State Machine Tournaments

```
Draft → Open      : Không điều kiện
Open  → Ready     : Confirmed >= Min (Singles: NumGroups*4, Doubles: NumGroups*8)
                    + Groups phải được tạo + Matches phải được tạo
Ready → InProgress: Tự động khi status chuyển
InProgress → Completed: Tất cả matches Complete
* → Cancelled     : Bất kỳ creator nào, cần reason nếu InProgress
```

---

## M4 — Participant & Group Management (`/api/tournaments/:id/...`)

| # | Method | Route | Auth | Status | Handler | Ghi chú |
|---|--------|-------|:----:|--------|---------|---------|
| 4.1 | GET | `/tournaments/:id/participants` | ❌ | ✅ Done | `GetParticipantsQueryHandler` | Trả confirmed/invited/request lists |
| 4.2 | POST | `/tournaments/:id/join` | ✅ | ✅ Done | `RequestJoinCommandHandler` | Validate Open + không full + chưa có request |
| 4.3 | POST | `/tournaments/:id/invite` | ✅ | ✅ Done | `InviteParticipantsCommandHandler` | Batch invite max 20, partial success |
| 4.4 | POST | `/tournaments/:id/participants/:pid/respond` | ✅ | ✅ Done | `RespondToRequestCommandHandler` | approve/reject |
| 4.5 | POST | `/tournaments/:id/groups` | ✅ | ✅ Done | `CreateGroupsCommandHandler` | Random preview + Manual confirm + Round Robin schedule |
| 4.6 | POST | `/tournaments/:id/teams` | ✅ | ⚠️ Thiếu | — | Tạo teams cho Doubles tournament |

### Request/Response nhanh

```
GET /tournaments/:id/participants
  Response: 200 { confirmed: ParticipantDto[], invited: ParticipantDto[], pending: ParticipantDto[] }

POST /tournaments/:id/join  [Authorize]
  Response: 201 { participantId, status: "RequestPending" }

POST /tournaments/:id/invite  [Authorize, Creator]
  Body: { userIds: string[] }  // max 20
  Response: 200 { invited: string[], errors: { userId, reason }[] }

POST /tournaments/:id/participants/:pid/respond  [Authorize, Creator]
  Body: { action: "approve" | "reject", reason? }
  Response: 200 { message }

POST /tournaments/:id/groups  [Authorize, Creator]
  Body: { mode: "random" | "manual", groups?: { name, memberIds }[] }
  Response: 201 { groups: GroupDetailDto[], matches: MatchDto[] }
```

### Logic CreateGroups

```
mode=random (preview): Shuffle confirmed participants → chia nhóm 4 người → KHÔNG lưu DB
mode=manual (confirm): Validate 4 members/group, no duplicates → Lưu Groups + GroupMembers + Matches
  → Tạo Round Robin: 3 rounds × (NumGroups × 2 matches) = 6 matches/group
  → Singles: Player1Id/Player2Id là userId
  → Doubles: Player1Id/Player2Id là teamId
```

---

## M5 — Match & Scoring (`/api/tournaments/:id/matches`, `/api/matches`)

| # | Method | Route | Auth | Status | Handler | Ghi chú |
|---|--------|-------|:----:|--------|---------|---------|
| 5.1 | GET | `/tournaments/:id/matches` | ❌ | ✅ Done | `GetMatchesQueryHandler` | List matches kèm group name |
| 5.2 | GET | `/tournaments/:id/draw` | ❌ | ⚠️ Thiếu | — | Bracket/draw visualization data |
| 5.3 | POST | `/matches/:id/score` | ✅ | ✅ Done | `SubmitScoreCommandHandler` | Submit scores, xác định winner, auto-complete tournament |
| 5.4 | PUT | `/matches/:id/score` | ✅ | ✅ Done | `UpdateScoreCommandHandler` | Sửa score đã submit, lưu history |
| 5.5 | GET | `/tournaments/:id/standings` | ❌ | ✅ Done | `GetGroupStandingsQueryHandler` | Bảng xếp hạng theo nhóm |
| 5.6 | GET | `/tournaments/:id/results` | ❌ | ✅ Done | `GetTournamentResultsQueryHandler` | Kết quả tổng hợp toàn giải |

### Request/Response nhanh

```
GET /tournaments/:id/matches?groupId=&status=
  Response: 200 { matches: MatchDto[] }

POST /matches/:id/score  [Authorize, Creator]
  Body: { player1Scores: int[], player2Scores: int[] }
  Response: 201 { MatchDetailDto } // includes winnerId

PUT /matches/:id/score  [Authorize, Creator]
  Body: { player1Scores: int[], player2Scores: int[], reason? }
  Response: 200 { MatchDetailDto }

GET /tournaments/:id/standings
  Response: 200 { groups: [{ groupName, standings: StandingDto[] }] }

GET /tournaments/:id/results
  Response: 200 { tournamentId, isComplete, groups: GroupResultStandingDto[] }
```

### Scoring Logic

```
ScoringFormat = BestOf1 : 1 set, winner = người thắng set đó
ScoringFormat = BestOf3 : 2-3 sets, winner = người thắng 2 sets
Standings points : Win = 3pts, Loss = 0pts (tie-break: sets won/lost ratio)
Auto-complete tournament: Khi tất cả matches đã Complete → TournamentStatus → Completed
```

---

## Modules Bỏ Qua (Per Request)

| Module | Route prefix | Lý do |
|--------|-------------|-------|
| Community Game | `/api/community-games` | Bỏ qua theo yêu cầu |
| Chat | `/api/chat` | Bỏ qua theo yêu cầu |
| Notification | `/api/notifications` | Bỏ qua theo yêu cầu |

---

## Features Chưa Implement (⚠️ Pending)

| Feature | Route | Độ ưu tiên | Lý do thiếu |
|---------|-------|:----------:|------------|
| Upload Avatar | `POST /users/me/avatar` | Medium | Cần `IStorageService` (S3/Azure Blob) |
| User Tournament History | `GET /users/me/tournaments` | Low | Query chưa build |
| Following List | `GET /users/me/following` | Low | Query chưa build |
| Followers List | `GET /users/me/followers` | Low | Query chưa build |
| User Match History | `GET /users/:id/matches` | Low | Query chưa build |
| Tournament Banner Upload | `POST /tournaments/:id/banner` | Low | Cần `IStorageService` |
| Create Teams (Doubles) | `POST /tournaments/:id/teams` | High | Cần thiết cho Doubles format |
| Draw/Bracket View | `GET /tournaments/:id/draw` | Medium | Data structure phức tạp |

---

## Build Status

```
Solution: AppPickleball.slnx (.NET 10)

AppPickleball.Domain         ✅ Build OK  (11 entities + 5 enums)
AppPickleball.Shared.Kernel  ✅ Build OK  (ApiResponse, PagedResponse, Localization)
AppPickleball.Application    ✅ Build OK  (CQRS handlers: Auth, User, Tournament, Participant, Match)
AppPickleball.Infrastructure ✅ Build OK  (EF Core + Repos + Services + DI)
AppPickleball.Api            ✅ Build OK  (Controllers + Middleware + DI)
AppPickleball.Tests          ✅ Build OK  (scaffold only)

Last build: 2026-03-13 — 0 errors, 0 warnings
```

---

## Cấu Trúc File Tổng Quan

```
AppPickleball.Application/Features/
├── Auth/
│   ├── Commands/Register/          RegisterCommand + Handler + Validator
│   ├── Commands/Login/             LoginCommand + Handler + Validator
│   ├── Commands/RefreshToken/      RefreshTokenCommand + Handler
│   ├── Commands/ChangePassword/    ChangePasswordCommand + Handler + Validator
│   ├── Commands/SendEmailVerification/
│   ├── Commands/VerifyEmail/
│   └── DTOs/                       AuthResponseDto, UserTokenDto, TokenResponseDto
│
├── Users/
│   ├── Queries/GetMyProfile/       GetMyProfileQuery + Handler
│   ├── Queries/GetUserProfile/     GetUserProfileQuery + Handler
│   ├── Commands/UpdateProfile/     UpdateProfileCommand + Handler + Validator
│   ├── Commands/Follow/            FollowCommand + Handler
│   ├── Commands/Unfollow/          UnfollowCommand + Handler
│   └── DTOs/                       UserProfileDto, PublicUserProfileDto, HeadToHeadDto
│
├── Tournaments/
│   ├── Queries/GetTournaments/     GetTournamentsQuery + Handler
│   ├── Queries/GetTournamentById/  GetTournamentByIdQuery + Handler
│   ├── Commands/CreateTournament/  + Handler + Validator
│   ├── Commands/UpdateTournament/  + Handler + Validator
│   ├── Commands/CancelTournament/  + Handler
│   ├── Commands/UpdateTournamentStatus/ + Handler + Validator
│   └── DTOs/                       TournamentDto, TournamentDetailDto, GroupDetailDto
│
├── Participants/
│   ├── Queries/GetParticipants/    + Handler
│   ├── Commands/RequestJoin/       + Handler + Validator
│   ├── Commands/InviteParticipants/ + Handler + Validator
│   ├── Commands/RespondToRequest/  + Handler + Validator
│   ├── Commands/CreateGroups/      + Handler + Validator
│   └── DTOs/                       ParticipantDto, ParticipantListDto
│
└── Matches/
    ├── Queries/GetMatches/         + Handler
    ├── Queries/GetGroupStandings/  + Handler
    ├── Queries/GetTournamentResults/ + Handler
    ├── Commands/SubmitScore/       + Handler + Validator
    ├── Commands/UpdateScore/       + Handler + Validator
    └── DTOs/                       MatchDto, MatchDetailDto, StandingDto, TournamentResultDto

AppPickleball.Api/Controllers/
├── AuthController.cs       11 endpoints (register, login, refresh, password, send-verification, verify-email, forgot-password, reset-password, google-login, facebook-login)
├── UserController.cs       5 endpoints
├── TournamentController.cs 11 endpoints
└── MatchController.cs      5 endpoints

AppPickleball.Application/Features/Auth/Commands/
├── GoogleLogin/            GoogleLoginCommand + GoogleLoginCommandHandler
└── FacebookLogin/          FacebookLoginCommand + FacebookLoginCommandHandler

AppPickleball.Infrastructure/Services/
├── GoogleAuthService.cs    IGoogleAuthService — verify Google ID Token (Google.Apis.Auth)
└── FacebookAuthService.cs  IFacebookAuthService — verify Facebook Access Token (Graph API)

AppPickleball.Infrastructure/Persistence/Repositories/
└── UserAuthProviderRepository.cs  IUserAuthProviderRepository — FindByProviderAsync
```

---

## Enums & Constants

```csharp
TournamentStatus : Draft | Open | Ready | InProgress | Completed | Cancelled
TournamentType   : Singles | Doubles
ScoringFormat    : BestOf1 | BestOf3
ParticipantStatus: Confirmed | InvitedPending | RequestPending | Rejected
MatchStatus      : Scheduled | InProgress | Completed | Walkover

MaxParticipants:
  Singles: NumGroups × 4
  Doubles: NumGroups × 4 × 2  (4 teams × 2 người/team)
```

---

## Authentication & Authorization

| Token | TTL | Storage |
|-------|-----|---------|
| Access Token (JWT) | 15 phút | Client memory |
| Refresh Token | 7 ngày | DB table `refresh_tokens` + Client storage |

```
JWT Claims: NameIdentifier (userId), email, name, emailVerified
SignalR: Token qua query string ?access_token=...
Reuse Detection: Refresh token đã revoke → Revoke tất cả tokens của user
```

---

## Error Codes Reference

| Exception | HTTP | ErrorCode |
|-----------|:----:|-----------|
| `ValidationException` | 400 | `VALIDATION_ERROR` |
| `NotFoundException` | 404 | `NOT_FOUND` |
| `DomainException` | 400 | `DOMAIN_ERROR` |
| `UnauthorizedAccessException` | 401 | `UNAUTHORIZED` |
| Unhandled | 500 | `INTERNAL_SERVER_ERROR` |

---

## Checklist Trước Khi Test

- [ ] PostgreSQL đang chạy + DB đã tạo (`create_pickleball_database.sql`)
- [ ] `appsettings.json` có `ConnectionStrings.DefaultConnection`
- [ ] `appsettings.json` có `Jwt: { SecretKey, Issuer, Audience }`
- [ ] `appsettings.json` có `Email: { SmtpHost, SmtpPort, Username, Password }`
- [ ] `dotnet run --project AppPickleball.Api` không có lỗi startup
- [ ] Swagger UI tại `https://localhost:{port}/swagger`
- [ ] Test flow: Register → Verify Email → Login → Create Tournament → Invite → Groups → Score

