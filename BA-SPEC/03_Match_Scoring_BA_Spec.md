# BA Spec — Match & Scoring

**Module:** M3 | **Phase:** 1

---

## F1. Quy Tắc Điểm

### Score Validation Rules
```
Một cặp điểm (s1, s2) là hợp lệ khi:
  - s1 >= 0 VÀ s2 >= 0
  - max(s1, s2) >= 11
  - |s1 - s2| >= 2
  - Chính xác 1 người thắng (không phải 2 người cùng >= 11)
```

### Xác Định Thắng Trận (best_of_3)
```
sets_won_p1 = số set s1 > s2
sets_won_p2 = số set s2 > s1

Thắng trận khi sets_won >= 2
Tối đa 3 set (dừng ngay khi 1 bên đạt 2 set thắng)
→ Không cho nhập set 3 nếu 1 bên đã thắng 2-0
```

### Acceptance Criteria
- [ ] Score [11-7] → hợp lệ, player 1 thắng set
- [ ] Score [11-10] → **không hợp lệ** (cách biệt không đủ 2)
- [ ] Score [12-10] → hợp lệ
- [ ] Score [10-11] → hợp lệ, player 2 thắng
- [ ] Score [15-13] → hợp lệ (deuce cao)
- [ ] Score [0-0] → không hợp lệ
- [ ] Score [-1-11] → không hợp lệ (âm)

---

## F2. Nhập Điểm

### Acceptance Criteria
- [ ] Chỉ Creator tournament mới nhập được
- [ ] Match phải ở status "scheduled" hoặc "in_progress"
- [ ] Nhập xong → Match.status = "completed", winnerId được set
- [ ] BXH cập nhật bất đồng bộ (async), UI poll hoặc nhận SignalR push
- [ ] Nếu đây là match cuối → tournament tự chuyển "completed"

### Business Rules
- Không cần nhập theo thứ tự vòng (có thể nhập vòng 2 trước vòng 1)
- Walkover match: không cần nhập điểm, winner được chỉ định trực tiếp

---

## F3. Sửa Điểm

### Acceptance Criteria
- [ ] Chỉ Creator mới sửa được
- [ ] Match phải đã "completed" (không sửa match "scheduled")
- [ ] Mỗi lần sửa → lưu vào MatchScoreHistories (audit log)
- [ ] Sau sửa → recalculate TOÀN BỘ standings của group đó
- [ ] Gửi notification đến 2 player trong trận "Điểm trận đấu đã được cập nhật"

### Audit Log Schema (MatchScoreHistories)
```
matchId, changedBy, oldPlayer1Scores, oldPlayer2Scores,
newPlayer1Scores, newPlayer2Scores, changedAt, reason (optional)
```

---

## F4. Bảng Xếp Hạng (Standings)

### Tính Toán
```
Với mỗi Player/Team trong 1 Group:
  W  = số matches có winnerId = playerId
  L  = số matches completed - W
  PF = tổng tất cả scores của player trong tất cả sets đã đấu
  PA = tổng scores của đối thủ
  Diff = PF - PA
```

### Thứ Tự Sắp Xếp (Tiebreaker Cascade)
1. W (giảm dần)
2. Diff = PF - PA (giảm dần)
3. H2H (đối đầu trực tiếp giữa 2 người bằng nhau)
4. Mini Round-Robin (nếu 3+ người bằng nhau, xét vòng tròn riêng)
5. PF / PA ratio (nếu vẫn bằng — trường hợp cực hiếm)

### Acceptance Criteria
- [ ] Standings cập nhật sau mỗi match completed
- [ ] Real-time push qua SignalR `StandingsUpdated`
- [ ] Hiển thị chính xác thứ hạng kể cả khi còn match chưa đấu

---

## F5. Kết Quả Tổng Giải

### Acceptance Criteria
- [ ] Chỉ hiển thị khi tournament.status = "completed"
- [ ] Hiển thị: hạng 1 của mỗi bảng (overall winner per group)
- [ ] Hiển thị: thống kê tổng (tổng matches, tổng points, top scorer)
- [ ] Kết quả cá nhân: W/L record, points scored

### Phase 3 (Future)
- Chia sẻ kết quả: tạo image card để post lên mạng xã hội
- Kết quả dùng để tính ELO rating

---

## F6. Sơ Đồ Thi Đấu (Bracket View)

### Acceptance Criteria
- [ ] Hiển thị tất cả bảng (A, B, C, D)
- [ ] Mỗi bảng hiển thị 6 trận theo Round Robin layout
- [ ] Trận completed: hiển thị điểm số
- [ ] Trận scheduled: hiển thị "vs"
- [ ] Click vào trận → popup chi tiết (Creator: nút nhập điểm)
- [ ] Real-time update khi có score mới (SignalR)

### Performance
- Bracket data được cache Redis 30s
- Client poll mỗi 30s nếu không dùng SignalR (fallback)
