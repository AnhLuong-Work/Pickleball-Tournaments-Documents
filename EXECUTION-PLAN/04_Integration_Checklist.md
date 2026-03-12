# Integration Checklist — Verify FE + BE + DB

**Chạy từng bước theo thứ tự. Không qua bước tiếp nếu bước trước fail.**

---

## Pre-conditions

```bash
# 1. BE đang chạy
curl -s https://localhost:7001/health  # {"status":"Healthy"}

# 2. DB có seed data
docker exec pickleball-postgres psql -U pickleballuser -d pickleballdb \
  -c "SELECT email FROM users LIMIT 3;"

# 3. FE đang chạy
curl -s http://localhost:5173  # HTML response
```

---

## Module M1 — Auth

### Test 1.1: Register
```bash
curl -s -X POST https://localhost:7001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@test.com","password":"Test@1234","name":"New User"}'
# ✅ Expected: 201, {"data":{"userId":"...","email":"newuser@test.com"}}
# ❌ If 409: Email đã tồn tại → đổi email khác
```

### Test 1.2: Login (với seed user)
```bash
curl -s -X POST https://localhost:7001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"Admin@123"}'
# ✅ Expected: 200, {"data":{"accessToken":"eyJ...","refreshToken":"..."}}
# Lưu accessToken vào biến:
TOKEN=$(curl -s -X POST ... | jq -r '.data.accessToken')
```

### Test 1.3: Get My Profile (authenticated)
```bash
curl -s https://localhost:7001/api/users/me \
  -H "Authorization: Bearer $TOKEN"
# ✅ Expected: 200, {"data":{"id":"...","name":"Admin","email":"admin@test.com"}}
```

### Test 1.4: Refresh Token
```bash
REFRESH=$(curl -s -X POST ... login | jq -r '.data.refreshToken')
curl -s -X POST https://localhost:7001/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}"
# ✅ Expected: 200, new accessToken + new refreshToken
```

### Test 1.5: Rate Limiting
```bash
for i in {1..6}; do
  curl -s -X POST https://localhost:7001/api/auth/login \
    -d '{"email":"x@x.com","password":"wrong"}' | grep -o '"status":[0-9]*'
done
# ✅ Expected: 5 × 401, 1 × 429
```

---

## Module M2 — Tournament

### Test 2.1: Create Tournament
```bash
curl -s -X POST https://localhost:7001/api/tournaments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Tournament","type":"singles","numGroups":1,"scoringFormat":"best_of_3"}'
# ✅ Expected: 201, tournamentId
TOURNAMENT_ID=$(... | jq -r '.data.id')
```

### Test 2.2: Publish Tournament
```bash
curl -s -X PUT "https://localhost:7001/api/tournaments/$TOURNAMENT_ID/status" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status":"open"}'
# ✅ Expected: 200
```

### Test 2.3: Request to Join (khác user)
```bash
TOKEN2=$(login với user2)
curl -s -X POST "https://localhost:7001/api/tournaments/$TOURNAMENT_ID/request" \
  -H "Authorization: Bearer $TOKEN2"
# ✅ Expected: 201
```

### Test 2.4: Approve Request
```bash
REQUEST_ID=$(GET /participants | jq -r '.data[0].requestId')
curl -s -X PUT "https://localhost:7001/api/tournaments/$TOURNAMENT_ID/requests/$REQUEST_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"action":"approve"}'
# ✅ Expected: 200, participant.status = "confirmed"
```

---

## Module M3 — Match Scoring

### Test 3.1: Create Groups (sau khi đủ 4 người)
```bash
curl -s -X POST "https://localhost:7001/api/tournaments/$TOURNAMENT_ID/groups/random" \
  -H "Authorization: Bearer $TOKEN"
# ✅ Expected: 201, groups created + matches scheduled
```

### Test 3.2: Submit Score
```bash
MATCH_ID=$(GET /matches | jq -r '.data[0].id')
curl -s -X POST "https://localhost:7001/api/matches/$MATCH_ID/score" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"player1Scores":[11,9,11],"player2Scores":[7,11,8]}'
# ✅ Expected: 200, match.status = "completed"
```

### Test 3.3: Standings Updated
```bash
GROUP_ID=$(GET /groups | jq -r '.data[0].id')
curl -s "https://localhost:7001/api/tournaments/$TOURNAMENT_ID/groups/$GROUP_ID/standings" \
  -H "Authorization: Bearer $TOKEN"
# ✅ Expected: standings với W/L/PF/PA calculated
```

---

## SignalR Integration Test

### Test S.1: Connect và Join Tournament
```javascript
// Chạy trong browser console khi FE đang mở tournament detail
// Check Network tab → WS → Messages:
// ✅ Should see: JoinTournament message sent
// ✅ When score submitted → ScoreUpdated received
// ✅ Standings table updates without page refresh
```

---

## FE-BE Integration Tests

### Test F.1: Login flow FE
```
1. Mở http://localhost:5173/auth/login
2. Nhập admin@test.com / Admin@123
3. ✅ Redirect đến /home
4. ✅ User name hiện trong header
5. ✅ localStorage có accessToken (hoặc memory store)
```

### Test F.2: Create Tournament từ FE
```
1. Click "+" button
2. Fill 3 bước form
3. Submit
4. ✅ Redirect về /tournaments/:id
5. ✅ Tournament status = draft
```

### Test F.3: Xem Live Score
```
1. Mở 2 browser windows cùng tournament detail
2. Window 1: login Creator → submit score
3. Window 2: ✅ Standings tự cập nhật (không cần refresh)
```

---

## Database Integrity Checks

```sql
-- Kiểm tra không có orphan records
SELECT COUNT(*) FROM participants p
LEFT JOIN tournaments t ON p.tournament_id = t.id
WHERE t.id IS NULL;
-- ✅ Expected: 0

-- Kiểm tra match scores valid
SELECT m.id, m.player1_scores, m.player2_scores
FROM matches m
WHERE m.status = 'completed'
AND jsonb_array_length(m.player1_scores) != jsonb_array_length(m.player2_scores);
-- ✅ Expected: 0 rows

-- Kiểm tra winner logic
SELECT id FROM matches
WHERE status = 'completed' AND winner_id IS NULL;
-- ✅ Expected: 0 rows
```

---

## Performance Checks

```bash
# API response time
time curl -s https://localhost:7001/api/tournaments  # < 200ms

# Concurrent requests
ab -n 100 -c 10 -H "Authorization: Bearer $TOKEN" \
  https://localhost:7001/api/tournaments
# ✅ Expected: 0 failed, mean < 500ms
```

---

## Final Sign-off Checklist

```
Phase 1 MVP Complete khi tất cả:

Auth:
  ✅ Register → Verify Email → Login → Get Token
  ✅ Refresh Token Rotation
  ✅ Rate Limiting 5 attempts
  ✅ Change Password → revoke all sessions

Tournament:
  ✅ Create → Publish → Open → Accept requests
  ✅ Random Groups → Schedule auto-created
  ✅ Status transitions đúng quy tắc

Match:
  ✅ Submit score → Winner detected → BXH updated
  ✅ SignalR push live → FE updates without refresh
  ✅ Edit score → re-calculate BXH

Profile:
  ✅ View/Edit profile
  ✅ Follow/Unfollow

Notification:
  ✅ In-app notification khi approve/invite
  ✅ Unread badge count

FE Integration:
  ✅ All protected routes redirect if not authenticated
  ✅ 401 auto-refresh token
  ✅ Error messages displayed properly
  ✅ Loading states on all async operations
```
