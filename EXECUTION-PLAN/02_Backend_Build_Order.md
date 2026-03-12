# Backend Build Order — Thứ Tự Build BE

**Tuân thủ đúng thứ tự. Verify sau mỗi bước bằng `dotnet build`.**

---

## Layer 1: Domain (Không có dependencies)

### Bước 1.1 — Base Classes
```
AppPickleball.Domain/Common/BaseEntity.cs
AppPickleball.Domain/Common/BaseCreatedEntity.cs
```
Fields:
- `BaseEntity`: Id(Guid), CreatedAt, UpdatedAt, DeletedAt, CreatedBy, UpdatedBy, DeletedBy, IsDeleted
- `BaseCreatedEntity`: Id(Guid), CreatedAt

### Bước 1.2 — Enums
```
Domain/Enums/TournamentStatus.cs      (draft,open,ready,in_progress,completed,cancelled)
Domain/Enums/TournamentType.cs        (singles,doubles)
Domain/Enums/ScoringFormat.cs         (best_of_1,best_of_3)
Domain/Enums/ParticipantStatus.cs     (confirmed,invited_pending,request_pending,rejected)
Domain/Enums/MatchStatus.cs           (scheduled,in_progress,completed,walkover)
Domain/Enums/NotificationType.cs      (tournament_invite,request_approved,...)
Domain/Enums/ChatRoomType.cs          (direct,group)
Domain/Enums/MessageType.cs           (text,image,system)
Domain/Enums/GameStatus.cs            (open,full,in_progress,completed,cancelled)
Domain/Enums/SkillLevel.cs            (beginner,intermediate,advanced,all)
```

### Bước 1.3 — Entities (theo thứ tự dependency)
```
# Auth group (không phụ thuộc nhau)
Domain/Entities/User.cs
Domain/Entities/UserAuthProvider.cs   (FK: UserId)
Domain/Entities/RefreshToken.cs       (FK: UserId)
Domain/Entities/EmailVerificationToken.cs
Domain/Entities/PasswordResetToken.cs

# Social (phụ thuộc User)
Domain/Entities/Follow.cs             (FK: FollowerId, FollowingId)

# Tournament group
Domain/Entities/Tournament.cs         (FK: CreatorId → User)
Domain/Entities/Participant.cs        (FK: TournamentId, UserId)
Domain/Entities/Team.cs               (FK: TournamentId, Player1Id, Player2Id)
Domain/Entities/Group.cs              (FK: TournamentId)
Domain/Entities/GroupMember.cs        (FK: GroupId, PlayerId?, TeamId?)
Domain/Entities/Match.cs              (FK: TournamentId, GroupId)
Domain/Entities/MatchScoreHistory.cs  (FK: MatchId)

# Chat group
Domain/Entities/ChatRoom.cs
Domain/Entities/ChatMember.cs         (FK: RoomId, UserId)
Domain/Entities/Message.cs            (FK: RoomId, SenderId)

# Notification
Domain/Entities/Notification.cs       (FK: UserId)
Domain/Entities/DeviceToken.cs        (FK: UserId)

# Community (Phase 2)
Domain/Entities/CommunityGame.cs      (FK: CreatorId)
Domain/Entities/GameParticipant.cs    (FK: GameId, UserId)
```

✅ `dotnet build` — 0 errors

---

## Layer 2: Share

```
Share/Wrappers/ApiResponse.cs          (ApiResponse<T>, ApiResponse, MetaResponse)
Share/Wrappers/PaginationResponse.cs
Share/Resources/SharedResource.cs      (marker class)
Share/Resources/SharedResource.resx    (default)
Share/Resources/SharedResource.en.resx
Share/Resources/SharedResource.vi.resx
```

✅ `dotnet build` — 0 errors

---

## Layer 3: Application — Common

### Bước 3.1 — Interfaces
```
Application/Common/Interfaces/IUnitOfWork.cs
Application/Common/Interfaces/IRepository.cs        (generic CRUD)
Application/Common/Interfaces/ISoftDeletableRepository.cs
Application/Common/Interfaces/ICurrentUserService.cs
Application/Common/Interfaces/IEmailService.cs
Application/Common/Interfaces/ICloudinaryService.cs
Application/Common/Interfaces/INotificationService.cs
Application/Common/Interfaces/ITokenService.cs
Application/Common/Interfaces/ICacheService.cs
Application/Common/Interfaces/IBaseDbContext.cs
```

### Bước 3.2 — Domain-specific Repository Interfaces
```
Application/Common/Interfaces/Repositories/IUserRepository.cs
Application/Common/Interfaces/Repositories/ITournamentRepository.cs
Application/Common/Interfaces/Repositories/IParticipantRepository.cs
Application/Common/Interfaces/Repositories/IMatchRepository.cs
Application/Common/Interfaces/Repositories/INotificationRepository.cs
Application/Common/Interfaces/Repositories/IRefreshTokenRepository.cs
```

### Bước 3.3 — Exceptions & Behaviours
```
Application/Common/Exceptions/NotFoundException.cs
Application/Common/Exceptions/ValidationException.cs
Application/Common/Exceptions/DomainException.cs
Application/Common/Exceptions/UnauthorizedException.cs
Application/Common/Behaviours/ValidationBehaviour.cs   (MediatR pipeline)
Application/Common/Behaviours/LoggingBehaviour.cs
```

### Bước 3.4 — Settings
```
Application/Common/Settings/JwtSettings.cs
Application/Common/Settings/EmailSettings.cs
Application/Common/Settings/CloudinarySettings.cs
Application/Common/Settings/AuthSettings.cs
```

✅ `dotnet build` — 0 errors

---

## Layer 4: Infrastructure

### Bước 4.1 — EF Configurations (theo thứ tự entity)
```
Infrastructure/Persistence/Configurations/UserConfiguration.cs
Infrastructure/Persistence/Configurations/RefreshTokenConfiguration.cs
Infrastructure/Persistence/Configurations/TournamentConfiguration.cs
Infrastructure/Persistence/Configurations/ParticipantConfiguration.cs
Infrastructure/Persistence/Configurations/TeamConfiguration.cs
Infrastructure/Persistence/Configurations/GroupConfiguration.cs
Infrastructure/Persistence/Configurations/GroupMemberConfiguration.cs
Infrastructure/Persistence/Configurations/MatchConfiguration.cs
Infrastructure/Persistence/Configurations/NotificationConfiguration.cs
Infrastructure/Persistence/Configurations/DeviceTokenConfiguration.cs
...
```

### Bước 4.2 — DbContext
```
Infrastructure/Persistence/PickleballDbContext.cs
  - Kế thừa DbContext, implement IBaseDbContext
  - SaveChangesAsync() override: auto-set UpdatedAt + normalize DateTime UTC
  - ApplyConfigurationsFromAssembly
```

### Bước 4.3 — Repositories
```
Infrastructure/Persistence/Repositories/RepositoryBase.cs      (generic impl)
Infrastructure/Persistence/Repositories/SoftDeletableRepository.cs
Infrastructure/Persistence/Repositories/UnitOfWork.cs
Infrastructure/Persistence/Repositories/UserRepository.cs
Infrastructure/Persistence/Repositories/TournamentRepository.cs
Infrastructure/Persistence/Repositories/ParticipantRepository.cs
Infrastructure/Persistence/Repositories/MatchRepository.cs
Infrastructure/Persistence/Repositories/NotificationRepository.cs
```

### Bước 4.4 — External Services
```
Infrastructure/Services/TokenService.cs       (JWT generate/validate)
Infrastructure/Services/EmailService.cs       (MailKit SMTP)
Infrastructure/Services/CloudinaryService.cs  (upload image)
Infrastructure/Services/CacheService.cs       (Redis StackExchange)
Infrastructure/Services/NotificationService.cs (save + SignalR push)
Infrastructure/Services/FCMService.cs         (push notification)
Infrastructure/Services/CurrentUserService.cs  (từ HttpContext)
```

### Bước 4.5 — DI Registration
```
Infrastructure/DependencyInjection.cs
  - AddDbContext<PickleballDbContext>
  - AddRepositories (scoped)
  - AddServices (scoped)
  - AddJwtAuthentication
  - AddRedis
```

✅ `dotnet build` — 0 errors

---

## Layer 5: Application — Features

**Thứ tự: M1 (Auth) → M2 (Tournament) → M3 (Match) → M7 (Notification)**

### M1 — Auth Features
```
Features/Auth/Commands/Register/RegisterCommand.cs + Handler + Validator
Features/Auth/Commands/Login/LoginCommand.cs + Handler + Validator
Features/Auth/Commands/RefreshToken/RefreshTokenCommand.cs + Handler
Features/Auth/Commands/VerifyEmail/VerifyEmailCommand.cs + Handler
Features/Auth/Commands/SendVerification/SendVerificationCommand.cs + Handler
Features/Auth/Commands/ChangePassword/ChangePasswordCommand.cs + Handler + Validator
Features/Auth/Commands/SocialLogin/SocialLoginCommand.cs + Handler
Features/Auth/Dtos/AuthResponseDto.cs
Features/Auth/Dtos/UserProfileDto.cs
```

### M1 — User Profile Features
```
Features/User/Queries/GetMyProfile/
Features/User/Commands/UpdateProfile/
Features/User/Commands/UploadAvatar/
Features/User/Queries/GetMyTournaments/
Features/User/Commands/Follow/
Features/User/Commands/Unfollow/
Features/User/Queries/GetFollowers/
Features/User/Queries/GetFollowing/
Features/User/Queries/GetUserProfile/
Features/User/Queries/GetUserMatches/
```

### M2 — Tournament Features
```
Features/Tournament/Commands/Create/
Features/Tournament/Commands/Update/
Features/Tournament/Commands/Cancel/
Features/Tournament/Commands/ChangeStatus/
Features/Tournament/Commands/UploadBanner/
Features/Tournament/Queries/GetList/
Features/Tournament/Queries/GetById/
```

### M2 — Participant Features
```
Features/Participant/Commands/Invite/
Features/Participant/Commands/Request/
Features/Participant/Commands/ApproveReject/
Features/Participant/Commands/Leave/
Features/Participant/Commands/Remove/
Features/Participant/Commands/CreateTeams/
Features/Participant/Commands/RandomTeams/
Features/Participant/Commands/AssignGroups/
Features/Participant/Commands/RandomGroups/
Features/Participant/Queries/GetParticipants/
```

### M3 — Match Features
```
Features/Match/Commands/SubmitScore/
Features/Match/Commands/UpdateScore/
Features/Match/Queries/GetSchedule/
Features/Match/Queries/GetBracket/
Features/Match/Queries/GetStandings/
Features/Match/Queries/GetResults/
```

### M7 — Notification Features
```
Features/Notification/Queries/GetNotifications/
Features/Notification/Commands/MarkRead/
Features/Notification/Commands/MarkAllRead/
Features/Notification/Commands/RegisterDevice/
```

✅ `dotnet build` — 0 errors

---

## Layer 6: API

### Bước 6.1 — Middleware
```
Api/Middleware/ExceptionHandlerMiddleware.cs
Api/Middleware/CorrelationIdMiddleware.cs
```

### Bước 6.2 — SignalR Hubs
```
Api/Hubs/TournamentHub.cs     (JoinTournament, LeaveTournament)
Api/Hubs/NotificationHub.cs   (auto-group by userId)
Api/Hubs/ChatHub.cs           (Phase 2)
```

### Bước 6.3 — Controllers (thin, delegate sang MediatR)
```
Api/Controllers/AuthController.cs
Api/Controllers/UsersController.cs
Api/Controllers/TournamentsController.cs
Api/Controllers/ParticipantsController.cs
Api/Controllers/MatchesController.cs
Api/Controllers/NotificationsController.cs
Api/Controllers/HealthController.cs
```

### Bước 6.4 — DI Extensions
```
Api/Extensions/ApplicationExtensions.cs   (AddApplication)
Api/Extensions/InfrastructureExtensions.cs
Api/Extensions/SwaggerExtensions.cs
Api/Extensions/CorsExtensions.cs
Api/Extensions/LocalizationExtensions.cs
Api/Program.cs                             (pipeline setup)
```

### Bước 6.5 — Config Files
```
Api/appsettings.json
Api/appsettings.Development.json
Api/Dockerfile
```

✅ **Final verify:**
```bash
dotnet build    # 0 errors, 0 warnings (critical)
dotnet run --project AppPickleball.Api
curl https://localhost:7001/health  # {"status":"Healthy"}
```
