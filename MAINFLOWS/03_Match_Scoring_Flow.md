# Match Scoring Flow — Luồng Trận Đấu & Ghi Điểm

**Module:** M3 — Match & Scoring | **Phase:** 1

---

## 1. Tổng Quan

```
Tournament.status = "in_progress"
    │
    ▼
Creator nhập điểm từng trận
    │
    ▼
Hệ thống tính toán người thắng
    │
    ▼
Cập nhật BXH bảng (async background job)
    │
    ▼
SignalR push live update đến tất cả client đang xem
    │
    ▼
Tất cả trận hoàn thành → Tournament auto-completed
```

---

## 2. Quy Tắc Điểm Pickleball

### Thắng set
- Đạt **11 điểm** trước
- Phải thắng cách biệt **ít nhất 2 điểm** (nếu 10-10 → phải đạt 12-10, 13-11, ...)
- Không có giới hạn điểm tối đa (deuce vô hạn)

### Thể thức
| ScoringFormat | Thắng khi | Số set tối đa |
|---------------|-----------|:-------------:|
| `best_of_1` | Thắng 1 set | 1 |
| `best_of_3` | Thắng 2 set | 3 |

### Ví dụ best_of_3
```
Set 1: A 11-7 B  → A thắng set 1
Set 2: A 9-11 B  → B thắng set 2
Set 3: A 11-8 B  → A thắng set 3
→ A thắng trận (2-1)
```

---

## 3. Nhập Điểm (Creator)

```
POST /matches/:id/score
{
  "player1Scores": [11, 9, 11],
  "player2Scores": [7, 11, 8]
}
    │
    ▼
Validation:
  1. Match.status phải là "scheduled" hoặc "in_progress"
  2. Tournament.creatorId == currentUserId
  3. Mỗi score >= 0
  4. Mỗi cặp điểm phải tạo ra winner rõ ràng:
     - Một bên đạt >=11 VÀ dẫn trước >=2
  5. Tổng số set phù hợp với scoringFormat
  6. Người thắng trận phải thắng đủ số set (1 hoặc 2)
    │
    ├─[Validation fail]──► 400 với chi tiết lỗi từng set
    │
    ▼
Match.player1Scores = [11, 9, 11]
Match.player2Scores = [7, 11, 8]
Match.winnerId = player1Id
Match.status = "completed"
Match.updatedAt = now
    │
    ▼
[Background Job] Tính lại standings của bảng
    │
    ▼
[SignalR] Broadcast ScoreUpdated + StandingsUpdated
    │
    ▼
[Check] Tất cả matches trong tournament completed?
  └─[Yes]──► Tournament.status = "completed"
```

---

## 4. Sửa Điểm (Creator)

```
PUT /matches/:id/score
    │
    ▼
Lưu lịch sử vào MatchScoreHistories (audit log)
    │
    ▼
Cập nhật Match scores + recalculate winnerId
    │
    ▼
[Background Job] Tính lại TOÀN BỘ standings của bảng
(vì điểm cũ đã được tính vào BXH)
    │
    ▼
[SignalR] Broadcast StandingsUpdated
```

---

## 5. Tính Toán Standings (Round Robin)

### Columns
| Cột | Mô tả |
|-----|-------|
| W | Số trận thắng |
| L | Số trận thua |
| PF | Points For (tổng điểm ghi được) |
| PA | Points Against (tổng điểm bị mất) |
| Diff | PF - PA |

### Thứ tự ưu tiên khi bằng nhau (Tiebreaker)
1. **Số trận thắng (W)** — nhiều hơn xếp trước
2. **Hiệu số điểm (Diff = PF - PA)** — cao hơn xếp trước
3. **Đối đầu trực tiếp (H2H)** — xét kết quả trận giữa 2 người/đội đó
4. **3 người bằng nhau** — xét vòng tròn riêng giữa 3 người đó (mini round-robin)

---

## 6. Walkover (Xử Thắng)

```
[Player bị xóa khi giải đang in_progress]
    │
    ▼
Tìm tất cả Matches chưa completed có player đó
    │
    ▼
Match.status = "walkover"
Match.winnerId = đối thủ còn lại
    │
    ▼
Tính lại standings
```

---

## 7. Live Score — SignalR Flow

```
Client (Web/Mobile) kết nối:
    hub.invoke("JoinTournament", tournamentId)
    │
    ▼ [Server lưu connectionId vào Group "tournament_{id}"]

Creator nhập điểm (POST /matches/:id/score)
    │
    ▼
Server gọi:
    hub.Clients.Group($"tournament_{tournamentId}")
        .SendAsync("ScoreUpdated", { matchId, player1Scores, player2Scores, winnerId })
    hub.Clients.Group($"tournament_{tournamentId}")
        .SendAsync("StandingsUpdated", { groupId, standings: [...] })
    │
    ▼
Tất cả clients đang theo dõi nhận update real-time
```

---

## 8. Xem Lịch Thi Đấu

```
GET /tournaments/:id/matches
Response:
{
  "groups": [
    {
      "groupId": 1,
      "groupName": "A",
      "rounds": [
        {
          "round": 1,
          "matches": [
            { "matchId": 1, "player1": {...}, "player2": {...}, "status": "completed", "scores": {...} },
            { "matchId": 2, ... }
          ]
        },
        { "round": 2, ... },
        { "round": 3, ... }
      ]
    }
  ]
}
```

**Phân quyền xem:**
- Creator: thấy tất cả bảng
- Player: thấy bảng của mình + kết quả các bảng khác (không thấy lịch chi tiết bảng khác)
