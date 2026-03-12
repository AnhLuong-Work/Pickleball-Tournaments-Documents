# Community Game Flow — Luồng Game Cộng Đồng

**Module:** M5 — Community | **Phase:** 2

---

## 1. Tổng Quan Trạng Thái

```
      [Creator tạo]
            │
            ▼
           OPEN ──────────────────► CANCELLED
        (đang mở,                   (Creator hủy,
         nhận người)                chỉ khi chưa in_progress)
            │
     [Đủ maxPlayers]
            │
            ▼
           FULL ──────────────────► CANCELLED
        (đủ người,
         vẫn có waitlist)
            │
      [Đến giờ chơi / Creator start]
            │
            ▼
       IN_PROGRESS
            │
      [Kết thúc]
            │
            ▼
         COMPLETED
```

---

## 2. Tạo Game

```
POST /community/games
{
  "title": "Game buổi sáng tại Hà Nội",
  "date": "2026-03-20T08:00:00Z",
  "location": "Sân Pickleball ABC, 123 Đường X, Hà Nội",
  "latitude": 21.0285,
  "longitude": 105.8542,
  "maxPlayers": 8,
  "skillLevel": "intermediate",
  "description": "Game giao lưu, welcome all"
}
    │
    ▼
Tạo CommunityGame { status: "open" }
    │
    ▼
Tự động tạo ChatRoom loại "group" cho game này
    │
    ▼
201 Created → { gameId, chatRoomId }
```

**Validation:**
- `date` phải trong tương lai (ít nhất 30 phút từ now)
- `maxPlayers`: 2–20
- `skillLevel`: `beginner` | `intermediate` | `advanced` | `all`
- Creator tự động được add vào GameParticipants (status: "confirmed") và ChatRoom

---

## 3. Tham Gia Game

```
POST /community/games/:id/join
    │
    ├─[Game status != "open" và != "full"]──► 422
    ├─[User đã là participant]──► 409
    │
    ▼
Đếm confirmed participants hiện tại
    │
    ├─[confirmed < maxPlayers]
    │     │
    │     ▼
    │  Tạo GameParticipant { status: "confirmed" }
    │  Add user vào ChatRoom
    │  Cập nhật game.status = "full" nếu confirmed = maxPlayers
    │
    └─[confirmed >= maxPlayers]
          │
          ▼
       Tạo GameParticipant { status: "waitlist" }
       KHÔNG add vào ChatRoom (chưa confirmed)
    │
    ▼
200 OK → { status: "confirmed" | "waitlist", position?: number }
```

---

## 4. Mời Người Chơi (Creator)

```
POST /community/games/:id/invite
{ "userIds": [1, 2, 3] }
    │
    ▼
Với mỗi userId:
  - Bỏ qua nếu đã là participant
  - Tạo GameParticipant { status: "invited_pending" }
  - Gửi Notification (loại: game_invite)
    │
    ▼
User nhận invite:
  POST /community/games/:id/join (accept invite)
  → GameParticipant.status = "confirmed"
```

---

## 5. Rời Game

```
DELETE /community/games/:id/leave
    │
    ├─[status = "in_progress" hoặc "completed"]──► 422
    │
    ▼
GameParticipant.status = "cancelled"
Remove user khỏi ChatRoom
    │
    ▼
[Nếu user rời và game.status = "full"]
  → Đẩy người đầu tiên từ waitlist lên confirmed
  → Add vào ChatRoom
  → game.status = "open" (có chỗ trống)
  → Gửi Notification cho người từ waitlist
```

---

## 6. Waitlist Auto-Promotion

```
Khi có chỗ trống (người rời hoặc bị xóa):
    │
    ▼
Tìm GameParticipant với status="waitlist" ORDER BY joinedAt ASC LIMIT 1
    │
    ├─[Có]──► GameParticipant.status = "confirmed"
    │         Add vào ChatRoom
    │         Gửi Notification: "Bạn đã vào danh sách chính thức"
    │
    └─[Không có]──► game.status = "open"
```

---

## 7. Lobby (Danh Sách Game)

```
GET /community/lobby
Query params:
  - date: filter theo ngày (default: hôm nay trở đi)
  - skillLevel: beginner | intermediate | advanced | all
  - hasSlots: true (chỉ game còn chỗ)
  - lat, lng, radius: tìm game gần vị trí (km)
  - page, pageSize
    │
    ▼
Sort mặc định: khoảng cách địa lý (nếu có lat/lng), rồi theo date ASC
    │
    ▼
Response bao gồm: gameInfo + confirmedCount + maxPlayers + waitlistCount
```

---

## 8. Hủy Game (Creator)

```
DELETE /community/games/:id
    │
    ├─[status = "in_progress" hoặc "completed"]──► 422
    │
    ▼
game.status = "cancelled"
    │
    ▼
Gửi Notification → tất cả confirmed participants
    │
    ▼
(Optional) Giải tán ChatRoom hoặc giữ lại để tham khảo
```
