# AppPickleball — Khuyến Nghị Thiết Kế Cơ Sở Dữ Liệu
**Ngày:** 2026-03-16 | **Loại:** Gợi ý thiết kế lại

---

## 1. 🔴 Các Vấn Đề Quan Trọng

### Vấn Đề 1: Bảng Users Quá Rộng
**Hiện tại:** Bảng Users có 13 cột trộn lẫn auth + profile + cài đặt

```sql
-- HIỆN TẠI (trộn lẫn các mối quan tâm)
CREATE TABLE Users (
  Id, Email, PasswordHash, Name, AvatarUrl, Bio,
  SkillLevel, DominantHand, PaddleType,
  EmailVerified, EmailVerifiedAt, EmailVerificationToken,
  CreatedAt, UpdatedAt
);
```

**Vấn Đề:**
- Khó bảo trì (quá nhiều trường)
- Không tách biệt các mối quan tâm
- Khó sửa đổi mà không cần di chuyển toàn bộ bảng
- Đăng nhập không cần SkillLevel hoặc PaddleType

**Khuyến nghị:** Chia thành 3 bảng

```sql
-- Auth aggregate
CREATE TABLE "Users" (
  "Id" INT PRIMARY KEY,
  "Email" VARCHAR(255) UNIQUE NOT NULL,
  "PasswordHash" VARCHAR(255),         -- NULL nếu chỉ social
  "IsEmailVerified" BOOLEAN DEFAULT FALSE,
  "CreatedAt" TIMESTAMPTZ,
  "UpdatedAt" TIMESTAMPTZ
);

-- Hồ sơ người dùng (tách riêng)
CREATE TABLE "UserProfiles" (ta
  "UserId" INT PRIMARY KEY FK,
  "Name" VARCHAR(100) NOT NULL,
  "AvatarUrl" VARCHAR(500),
  "Bio" TEXT,
  "SkillLevel" DECIMAL(2,1) DEFAULT 3.0,
  "DominantHand" VARCHAR(10),
  "PaddleType" VARCHAR(100),
  "UpdatedAt" TIMESTAMPTZ
);

-- Xác thực email (tách riêng)
CREATE TABLE "EmailVerifications" (
  "Id" INT PRIMARY KEY,
  "UserId" INT FK UNIQUE,             -- Tối đa 1 xác thực chờ xử lý/người dùng
  "Code" VARCHAR(6) NOT NULL,
  "CodeHash" VARCHAR(255),            -- Hash của mã
  "Attempts" INT DEFAULT 0,
  "ExpiresAt" TIMESTAMPTZ,
  "VerifiedAt" TIMESTAMPTZ,
  "CreatedAt" TIMESTAMPTZ
);
```

**Lợi ích:**
- Tách biệt sạch sẽ (Auth vs Profile vs Verification)
- Dễ quản lý xác thực password/email riêng biệt
- Có thể lazy-load hồ sơ khi cần
- Truy vấn auth nhanh hơn (bảng nhỏ hơn)

---

### Vấn Đề 2: Khả Năng Giải Đấu Cố Định

**Hiện tại:**
- Singles: 1-4 bảng → 4, 8, 12 hoặc 16 người chơi (cố định)
- Doubles: 1-2 bảng → 8 hoặc 16 người chơi (cố định)

```sql
-- HIỆN TẠI
CREATE TABLE "Tournaments" (
  "Id", "Name", "Type", "NumGroups",  -- Singles/Doubles với 1-4 bảng
  "Status", "CreatedAt"
);

-- Quy tắc khả năng: Type=singles & NumGroups=2 → phải có chính xác 8 người chơi
```

**Vấn Đề:**
- ❌ Không linh hoạt (không thể có 7 người chơi với 1 bye)
- ❌ Không thể chạy giải đấu với 9 người chơi
- ❌ Buộc từ chối người chơi nếu đạt X-1
- ❌ Không có overflow/waitlist
- ❌ Không hỗ trợ kích thước giải đấu linh hoạt

**Khuyến nghị:** Thêm min/max capacity + waitlist

```sql
CREATE TABLE "Tournaments" (
  "Id" INT PRIMARY KEY,
  "Name" VARCHAR(200) NOT NULL,
  "Type" VARCHAR(20) NOT NULL,        -- 'singles', 'doubles'
  "Format" VARCHAR(20) DEFAULT 'round_robin',  -- MỚI: 'round_robin', 'bracket', 'swiss'
  "MinCapacity" INT NOT NULL,         -- ví dụ: 4
  "MaxCapacity" INT NOT NULL,         -- ví dụ: 16
  "CurrentCapacity" INT DEFAULT 0,    -- Denormalized để perf
  "Status" VARCHAR(20) NOT NULL,
  "ScoringFormat" VARCHAR(20),
  "CreatedAt" TIMESTAMPTZ,
  "UpdatedAt" TIMESTAMPTZ
);

-- MỚI: Hỗ trợ waitlist
CREATE TABLE "TournamentWaitlist" (
  "Id" INT PRIMARY KEY,
  "TournamentId" INT FK,
  "UserId" INT FK,
  "Position" INT,                     -- Thứ tự waitlist
  "JoinedAt" TIMESTAMPTZ
);
```

**Lợi ích:**
- Khả năng linh hoạt (4-16 thay vì 4/8/12/16)
- Hỗ trợ waitlist (nếu ai đó hủy, người tiếp theo trong hàng đợi tham gia)
- Hỗ trợ nhiều định dạng (chuẩn bị cho bracket/swiss)
- Có thể chạy giải đấu bất kỳ kích thước nào

---

### Vấn Đề 3: Điểm Trận Đấu Được Lưu Dưới Dạng JSONB

**Hiện tại:**
```sql
CREATE TABLE "Matches" (
  "Id", "Player1Id", "Player2Id",
  "Player1Scores" JSONB,    -- {"game1": 11, "game2": 9}
  "Player2Scores" JSONB,
  "WinnerId", "Status"
);

-- Không rõ cách truy vấn: "Tìm tất cả trận đấu nơi Player1 ghi được > 10"
-- Định dạng không rõ: Nó là mảng? Đối tượng?
-- Khó thực thi schema
```

**Vấn Đề:**
- ❌ Không có kiểu (có thể là {"g1": 11} hoặc [11, 9])
- ❌ Không thể truy vấn hiệu quả ("tìm trận với điểm 11-9")
- ❌ Không xác thực ở cấp DB
- ❌ Khó sửa (ví dụ: sửa một điểm)
- ❌ Không xử lý hòa/tied

**Khuyến nghị:** Sử dụng bảng MatchGame riêng biệt

```sql
CREATE TABLE "Matches" (
  "Id" INT PRIMARY KEY,
  "TournamentId" INT FK,
  "GroupId" INT FK,
  "Round" INT,
  "MatchOrder" INT,
  "MatchType" VARCHAR(20),            -- 'singles', 'doubles'
  "Player1Id" INT FK,                 -- Với singles: UserId, với doubles: TeamId
  "Player2Id" INT FK,
  "TournamentFormat" VARCHAR(20),     -- 'best_of_1', 'best_of_3'
  "Status" VARCHAR(20),               -- 'scheduled', 'in_progress', 'completed', 'walkover'
  "WinnerId" INT FK,                  -- NULL nếu hòa/chưa chơi
  "MatchResult" VARCHAR(20),          -- 'player1_win', 'player2_win', 'draw', 'walkover'
  "StartedAt" TIMESTAMPTZ,
  "CompletedAt" TIMESTAMPTZ,
  "CreatedAt" TIMESTAMPTZ
);

-- MỚI: Mỗi trò chơi được ghi điểm riêng biệt (strongly typed)
CREATE TABLE "MatchGames" (
  "Id" INT PRIMARY KEY,
  "MatchId" INT FK,
  "GameNumber" INT,                   -- 1, 2, 3 cho best_of_3
  "Player1Score" INT NOT NULL,        -- 0-15
  "Player2Score" INT NOT NULL,
  "WinnerId" INT FK,                  -- Ai thắng trò chơi này
  "Status" VARCHAR(20),               -- 'in_progress', 'completed'
  "CompletedAt" TIMESTAMPTZ
);

-- Ví dụ truy vấn:
-- SELECT * FROM Matches WHERE WinnerId = @userId AND Status = 'completed'
-- SELECT * FROM Matches m JOIN MatchGames g ON m.Id = g.MatchId WHERE g.Player1Score > 10
```

**Lợi ích:**
- Strongly typed (không thể có điểm không hợp lệ)
- Có thể truy vấn (SELECT * WHERE Player1Score = 11)
- Hỗ trợ best_of_1, best_of_3
- Hỗ trợ walkover/hòa
- Dễ sửa lại một điểm của một trò chơi
- Có thể theo dõi thời lượng trò chơi, người thắng cho mỗi trò chơi

---

### Vấn Đề 4: GroupMembers Khó Hiểu Cho Singles vs Doubles

**Hiện tại:**
```sql
CREATE TABLE "GroupMembers" (
  "Id", "GroupId", "PlayerId",  -- PlayerId cho singles
  "TeamId",                      -- TeamId cho doubles (trộn lẫn khó hiểu)
  "SeedOrder"
);

-- Không rõ: đây là người chơi hay đội?
-- Với singles: PlayerId điền, TeamId NULL
-- Với doubles: TeamId điền, PlayerId NULL
```

**Vấn Đề:**
- ❌ Trộn lẫn các loại entity (Player vs Team)
- ❌ Khó truy vấn ("Lấy tất cả thành viên của nhóm X" → cần join với Players/Teams)
- ❌ Logic khó hiểu

**Khuyến nghị:** Tách các bảng theo loại giải đấu

```sql
-- Cho giải đấu Singles
CREATE TABLE "SinglesGroupMembers" (
  "Id" INT PRIMARY KEY,
  "GroupId" INT FK,
  "PlayerId" INT FK,              -- Luôn là người chơi
  "SeedOrder" INT,
  "CreatedAt" TIMESTAMPTZ
);

-- Cho giải đấu Doubles
CREATE TABLE "DoublesGroupMembers" (
  "Id" INT PRIMARY KEY,
  "GroupId" INT FK,
  "TeamId" INT FK,                -- Luôn là đội
  "SeedOrder" INT,
  "CreatedAt" TIMESTAMPTZ
);

-- Hoặc phương pháp polymorphic:
CREATE TABLE "GroupMembers" (
  "Id" INT PRIMARY KEY,
  "GroupId" INT FK,
  "EntityType" VARCHAR(20),       -- 'player', 'team'
  "EntityId" INT,                 -- PlayerId hoặc TeamId
  "SeedOrder" INT,
  CHECK (EntityType IN ('player', 'team'))
);
```

**Lợi ích:**
- Ý định rõ ràng (Nhóm chứa hoặc Người chơi hoặc Đội, không phải cả hai)
- Truy vấn type-safe
- Dễ xác thực (FK constraint)

---

## 2. 🟡 Vấn Đề Hiệu Suất

### Vấn Đề 5: Không Có Indexes Được Ghi Chép

**Hiện tại:** Thiết kế cơ sở dữ liệu không đề cập đến indexes

**Khuyến nghị:** Thêm các indexes chiến lược

```sql
-- Truy vấn Auth
CREATE INDEX idx_users_email ON "Users"("Email");
CREATE INDEX idx_users_email_verified ON "Users"("Email", "IsEmailVerified");

-- Khám phá Giải Đấu
CREATE INDEX idx_tournaments_status_date ON "Tournaments"("Status", "Date" DESC);
CREATE INDEX idx_tournaments_creator ON "Tournaments"("CreatorId", "CreatedAt" DESC);
CREATE INDEX idx_tournaments_location ON "Tournaments"("Location");

-- Truy vấn Người Tham Gia
CREATE INDEX idx_participants_tournament_status ON "Participants"("TournamentId", "Status");
CREATE INDEX idx_participants_user_tournament ON "Participants"("UserId", "TournamentId") UNIQUE;

-- Truy vấn Match (có thể grow lớn)
CREATE INDEX idx_matches_tournament ON "Matches"("TournamentId");
CREATE INDEX idx_matches_group ON "Matches"("GroupId");
CREATE INDEX idx_matches_player1 ON "Matches"("Player1Id");
CREATE INDEX idx_matches_player2 ON "Matches"("Player2Id");
CREATE INDEX idx_matches_status_completed ON "Matches"("Status", "CompletedAt" DESC);

-- Truy vấn Game Score
CREATE INDEX idx_match_games_match ON "MatchGames"("MatchId");
CREATE INDEX idx_match_games_player1_score ON "MatchGames"("Player1Score");

-- Chat/Messages (Phase 2, có thể grow rất lớn)
CREATE INDEX idx_messages_room_date ON "Messages"("RoomId", "CreatedAt" DESC);
CREATE INDEX idx_messages_sender ON "Messages"("SenderId", "CreatedAt" DESC);

-- Truy vấn Notification
CREATE INDEX idx_notifications_user_read ON "Notifications"("UserId", "IsRead", "CreatedAt" DESC);

-- Truy vấn Follow
CREATE INDEX idx_follows_follower ON "Follows"("FollowerId");
CREATE INDEX idx_follows_following ON "Follows"("FollowingId");
```

**Lợi ích:**
- Truy vấn nhanh cho các hoạt động thường xuyên
- Giảm full table scans
- Hỗ trợ phân trang (sắp xếp theo ngày)

---

### Vấn Đề 6: Không Có Denormalization Cho Hot Reads

**Hiện tại:** Truy vấn COUNT yêu cầu aggregation

```sql
-- Không hiệu quả: đếm người dùng, tổng hợp kết quả
SELECT COUNT(*) FROM Participants WHERE TournamentId = 1 AND Status = 'confirmed'
```

**Khuyến nghị:** Denormalize counts

```sql
CREATE TABLE "Tournaments" (
  "Id",
  "ConfirmedCount" INT DEFAULT 0,     -- Denormalized
  "WaitlistCount" INT DEFAULT 0,
  "UpdatedAt"
);

-- Trigger để cập nhật counts
CREATE TRIGGER update_tournament_counts
AFTER INSERT OR UPDATE OR DELETE ON Participants
FOR EACH ROW
BEGIN
  UPDATE Tournaments
  SET ConfirmedCount = (SELECT COUNT(*) FROM Participants WHERE TournamentId = NEW.TournamentId AND Status = 'confirmed'),
      WaitlistCount = (SELECT COUNT(*) FROM Participants WHERE TournamentId = NEW.TournamentId AND Status = 'waitlist')
  WHERE Id = NEW.TournamentId;
END;
```

**Lợi ích:**
- Truy vấn O(1) để kiểm tra khả năng
- Không cần aggregation
- Hiệu suất tốt hơn khi scale

---

## 3. 🟢 Bảng Mới Cần Thiết

### Bảng 1: AuditLogs (Security)
```sql
CREATE TABLE "AuditLogs" (
  "Id" BIGINT PRIMARY KEY,
  "UserId" INT FK,
  "Action" VARCHAR(50),
  "ResourceType" VARCHAR(50),
  "ResourceId" INT,
  "OldValues" JSONB,
  "NewValues" JSONB,
  "IPAddress" VARCHAR(45),
  "UserAgent" VARCHAR(500),
  "StatusCode" INT,
  "CreatedAt" TIMESTAMPTZ
);

CREATE INDEX idx_audit_user_date ON "AuditLogs"("UserId", "CreatedAt" DESC);
CREATE INDEX idx_audit_resource ON "AuditLogs"("ResourceType", "ResourceId");
```

### Bảng 2: UserSessions (Device Management)
```sql
CREATE TABLE "UserSessions" (
  "Id" INTEGER PRIMARY KEY,
  "UserId" INT FK,
  "DeviceId" VARCHAR(255),
  "DeviceName" VARCHAR(255),
  "IPAddress" VARCHAR(45),
  "UserAgent" VARCHAR(500),
  "RefreshTokenHash" VARCHAR(255) UNIQUE,
  "LastUsedAt" TIMESTAMPTZ,
  "ExpiresAt" TIMESTAMPTZ,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMPTZ
);

CREATE INDEX idx_sessions_user_active ON "UserSessions"("UserId", "IsActive");
CREATE INDEX idx_sessions_token_hash ON "UserSessions"("RefreshTokenHash");
```

### Bảng 3: RateLimitLogs (API Protection)
```sql
CREATE TABLE "RateLimitLogs" (
  "Id" INTEGER PRIMARY KEY,
  "Key" VARCHAR(255),                 -- "login_192.168.1.1", "api_user_123"
  "Attempts" INT DEFAULT 1,
  "LastAttemptAt" TIMESTAMPTZ DEFAULT NOW(),
  "ExpiresAt" TIMESTAMPTZ
);

CREATE UNIQUE INDEX idx_ratelimit_key ON "RateLimitLogs"("Key");
```

### Bảng 4: MatchAppeals (Dispute Resolution)
```sql
-- MỚI: Khi người chơi tranh cãi một kết quả
CREATE TABLE "MatchAppeals" (
  "Id" INTEGER PRIMARY KEY,
  "MatchId" INT FK,
  "AppealedByUserId" INT FK,
  "Reason" TEXT,
  "Status" VARCHAR(20) DEFAULT 'pending',  -- 'pending', 'approved', 'rejected', 'cancelled'
  "ReviewedByUserId" INT FK,
  "ReviewNotes" TEXT,
  "CreatedAt" TIMESTAMPTZ,
  "ResolvedAt" TIMESTAMPTZ
);
```

---

## 4. 📋 Thay Đổi Schema Cần Thiết

### Thay Đổi Bảng Hiện Tại

#### Users → Email Verification
```sql
-- Xóa các cột từ Users
-- Users.EmailVerifiedAt → EmailVerifications.VerifiedAt
-- Users.EmailVerificationToken → EmailVerifications.Code

ALTER TABLE "Users"
DROP COLUMN "EmailVerifiedAt",
DROP COLUMN "EmailVerificationToken";

-- Ghi chú: EmailVerified ở lại để kiểm tra nhanh trạng thái
```

#### Tournaments → Hỗ Trợ Nhiều Định Dạng
```sql
ALTER TABLE "Tournaments"
ADD COLUMN "Format" VARCHAR(20) DEFAULT 'round_robin',
ADD COLUMN "MinCapacity" INT,
ADD COLUMN "MaxCapacity" INT,
ADD COLUMN "CurrentCapacity" INT DEFAULT 0,
ALTER COLUMN "NumGroups" DROP NOT NULL;  -- Tùy chọn cho định dạng bracket
```

#### Matches → Chia Tách Scores
```sql
-- Không xóa Player1Scores/Player2Scores chưa
-- Tạo bảng MatchGames song song
-- Di chuyển dữ liệu: phân tích JSONB và tạo record MatchGame
-- Giữ các cột cũ để backward compat, đánh dấu deprecated
-- Xóa trong v2.0
```

---

## 5. 📊 Bảng Tóm Tắt

| Vấn Đề | Mức Độ Nghiêm Trọng | Hiện Tại | Khuyến Nghị | Lợi Ích |
|--------|-----------|---------|-------------|---------|
| Bảng Users quá rộng | 🔴 Cao | 1 bảng (13 col) | 3 bảng (Users, UserProfiles, EmailVerifications) | Tách biệt sạch sẽ, bảo trì dễ hơn |
| Khả năng giải đấu cố định | 🔴 Cao | 4/8/12/16 cố định | Min/Max linh hoạt | Hỗ trợ waitlist, kích thước linh hoạt |
| Điểm JSONB trận đấu | 🔴 Cao | JSONB untyped | Bảng MatchGames | Có thể truy vấn, typed, auditable |
| GroupMembers trộn loại | 🟡 Trung Bình | Players + Teams trộn | Tách bảng theo định dạng | Ý định rõ ràng, type-safe |
| Không có indexes | 🟡 Trung Bình | Không được ghi chú | 15+ indexes chiến lược | Truy vấn nhanh 10-100x |
| Không denormalization | 🟡 Trung Bình | Count aggregation | Denormalized counts | Kiểm tra khả năng O(1) |
| Không audit logging | 🔴 Cao | Không | Bảng AuditLogs | Bảo mật, compliance, gỡ lỗi |
| Không quản lý phiên | 🔴 Cao | RefreshTokens cơ bản | Bảng UserSessions | Đa thiết bị, thu hồi |
| Không rate limiting DB | 🟡 Trung Bình | Không | Bảng RateLimitLogs | Bảo vệ DDoS |
| Không giải quyết tranh cãi | 🟡 Trung Bình | Không | Bảng MatchAppeals | Xử lý kết quả tranh cãi |

---

## Đường Dẫn Triển Khai

### Phase 1: Thay Đổi Quan Trọng (Tuần 1-2)
1. ✅ Chia bảng Users (Users → UserProfiles → EmailVerifications)
2. ✅ Thêm bảng AuditLogs + UserSessions
3. ✅ Thêm các indexes chiến lược
4. ✅ Cập nhật Tournaments (khả năng linh hoạt)

### Phase 2: Xử Lý Scores (Tuần 3)
1. ✅ Tạo bảng MatchGames
2. ✅ Di chuyển dữ liệu scores
3. ✅ Cập nhật API để sử dụng MatchGames
4. ✅ Giữ các cột cũ deprecated

### Phase 3: Cải Thiện (Tuần 4+)
1. ✅ Thêm bảng MatchAppeals
2. ✅ Thêm RateLimitLogs + triggers
3. ✅ Denormalize tournament counts
4. ✅ Thêm MatchAppeals, CommunityGameAppeals

---

*Những cải thiện cơ sở dữ liệu này sẽ cung cấp bảo mật, hiệu suất và tính linh hoạt cho tăng trưởng trong tương lai.*
