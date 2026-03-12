# Tournament Lifecycle Flow — Vòng Đời Giải Đấu

**Module:** M2 — Tournament Management | **Phase:** 1

---

## 1. Tổng Quan Trạng Thái

```
        [Creator tạo]
              │
              ▼
           DRAFT ────────────────────────────────┐
         (bản nháp,                              │
         chưa công khai)                         │
              │                                  │
         [Creator "Xuất bản"]                    │
              │                                  │
              ▼                                  │
            OPEN                                 │
         (nhận đăng ký)                          │  CANCELLED
              │                                  │  (Creator hủy,
     [Đủ người + Creator "Đóng đăng ký"]         │  bất kỳ lúc nào
              │                                  │  trước completed)
              ▼                                  │
           READY                                 │
         (đã xếp bảng,                           │
          sẵn sàng)                              │
              │                                  │
         [Creator "Bắt đầu"]                     │
              │                                  │
              ▼                                  │
         IN_PROGRESS ───────────────────────────►┘
         (đang thi đấu)
              │
         [Tất cả matches completed]
              │ (tự động)
              ▼
          COMPLETED
```

---

## 2. Tạo Giải Đấu (draft)

```
Creator fill form:
  - name (bắt buộc)
  - type: singles | doubles
  - numGroups: 1-4 (singles) hoặc 1-2 (doubles)
  - scoringFormat: best_of_1 | best_of_3
  - date, location, description, bannerUrl (tùy chọn)
    │
    ▼
POST /tournaments
    │
    ▼
Tạo Tournament { status: "draft" }
Hiển thị "Cần tối thiểu X người để bắt đầu":
  - Singles: numGroups × 4
  - Doubles: numGroups × 4 × 2 (số người, 2 người/đội)
    │
    ▼
201 Created → tournamentId
```

---

## 3. Giai Đoạn OPEN — Quản Lý Người Tham Gia

### 3a. Mời người chơi (Creator → User)
```
POST /tournaments/:id/invite { userId }
    │
    ▼
Tạo Participant { status: "invited_pending" }
    │
    ▼
Gửi Notification → User (loại: tournament_invite)
    │
    ▼
User xác nhận: PUT /tournaments/:id/requests/:rid { action: "accept" }
    │
    ▼
Participant.status = "confirmed"
```

### 3b. User tự xin tham gia
```
POST /tournaments/:id/request
    │
    ├─[Giải không ở status "open"]──► 422
    ├─[User đã có participant record]──► 409
    ├─[Giải đã đầy (confirmed >= maxCapacity)]──► 422
    │
    ▼
Tạo Participant { status: "request_pending" }
    │
    ▼
Gửi Notification → Creator (cần xét duyệt)
    │
    ▼
Creator duyệt: PUT /tournaments/:id/requests/:rid
  - action: "approve" → Participant.status = "confirmed"
  - action: "reject"  → Participant.status = "rejected"
```

**Capacity tối đa:**
| Type | numGroups | Max participants |
|------|:---------:|:----------------:|
| Singles | 1 | 4 |
| Singles | 2 | 8 |
| Singles | 3 | 12 |
| Singles | 4 | 16 |
| Doubles | 1 | 8 (4 đội × 2) |
| Doubles | 2 | 16 (8 đội × 2) |

---

## 4. Chuyển OPEN → READY (Ghép đội + Xếp bảng)

### Bước 4a: Ghép đội (Chỉ Doubles)
```
Creator ghép đội (manual hoặc random):
    │
    ├─ Manual: POST /tournaments/:id/teams
    │          { teamPairs: [{ player1Id, player2Id }, ...] }
    │
    └─ Random: POST /tournaments/:id/teams/random
               │
               ▼
               Thuật toán Fisher-Yates shuffle
               Trả về preview (chưa lưu)
               Creator confirm → lưu
```

### Bước 4b: Xếp bảng
```
Creator xếp bảng (manual hoặc random):
    │
    ├─ Manual: POST /tournaments/:id/groups
    │          { groupAssignments: [{ groupName: "A", memberIds: [...] }] }
    │
    └─ Random: POST /tournaments/:id/groups/random
               │
               ▼
               Thuật toán random, trả về preview
               Creator confirm → lưu
    │
    ▼
Sau khi xếp bảng xong:
    - Hệ thống tự động tạo LỊCH ĐẤU (Round Robin schedule)
    - Mỗi bảng 4 đơn vị → 6 trận, 3 vòng
    - Tạo tất cả Match records { status: "scheduled" }
    │
    ▼
Tournament.status = "ready"
Gửi Notification → tất cả Participants (loại: match_scheduled)
```

### Lịch đấu Round Robin (4 đơn vị/bảng)
```
Vòng 1: A vs B, C vs D
Vòng 2: A vs C, B vs D
Vòng 3: A vs D, B vs C
```

---

## 5. Giai Đoạn IN_PROGRESS

```
Creator nhấn "Bắt đầu giải"
    │
    ▼
PUT /tournaments/:id/status { status: "in_progress" }
    │
    ▼
Tournament.status = "in_progress"
Gửi Notification → tất cả Participants (loại: tournament_started)
```

→ Chuyển sang [Match Scoring Flow](./03_Match_Scoring_Flow.md)

---

## 6. Tự Động COMPLETED

```
Trận đấu cuối cùng được nhập điểm
    │
    ▼
Background job kiểm tra:
  Tất cả Matches trong tournament có status = "completed" hoặc "walkover"?
    │
    ├─[Chưa]──► tiếp tục
    │
    ▼
Tournament.status = "completed"
Gửi Notification → tất cả Participants (loại: tournament_completed)
Cập nhật lịch sử giải đấu của từng Player
```

---

## 7. Hủy Giải (CANCELLED)

```
PUT /tournaments/:id/status { status: "cancelled", reason: "..." }
    │
    ├─[status đã là "completed"]──► 422 "Không thể hủy giải đã kết thúc"
    │
    ▼
Tournament.status = "cancelled"
Gửi Notification → tất cả Participants (loại: tournament_cancelled, kèm reason)
```

---

## 8. Rời Giải / Xóa Người Chơi

```
[Player rời giải]
DELETE /tournaments/:id/participants/:userId (self)
    │
    ├─[status = "in_progress"]──► 422 "Không thể rời giải đang diễn ra"
    │
    ▼
Xóa Participant record
Nếu đã xếp bảng (status = "ready") → Creator phải xếp lại bảng

[Creator xóa người chơi]
DELETE /tournaments/:id/participants/:userId (by creator)
    │
    ├─[status = "in_progress"]──► Dùng WALKOVER cho các trận còn lại
    │
    ▼
Participant.status = "rejected"
```
