# BA Spec — Community Game

**Module:** M5 | **Phase:** 2

---

## F1. Tạo Game Cộng Đồng

### Acceptance Criteria
- [ ] Bất kỳ user nào cũng có thể tạo game (không chỉ Creator giải đấu)
- [ ] Sau khi tạo → Creator tự động là confirmed participant
- [ ] Tự động tạo GroupChat cho game
- [ ] `date` phải ít nhất 30 phút trong tương lai

### Validation Rules
| Field | Rule |
|-------|------|
| `title` | Required, 3–200 ký tự |
| `date` | Required, phải > now + 30 phút |
| `location` | Required, max 500 ký tự |
| `maxPlayers` | Required, 2–20 |
| `skillLevel` | `beginner` \| `intermediate` \| `advanced` \| `all` |

### Business Rules
- Creator không thể tự xóa mình khỏi game (luôn là confirmed)
- Nếu Creator rời game → cần chỉ định host mới (Phase 2 feature)

---

## F2. Tham Gia Game

### Acceptance Criteria
- [ ] Game.status phải là "open" (có chỗ) hoặc "full" (vào waitlist)
- [ ] User đã confirmed/invited_pending → 409
- [ ] Tham gia thành công → add vào ChatRoom tự động
- [ ] Vào waitlist → KHÔNG add vào ChatRoom

### Race Condition Handling
```
Khi 2 user cùng tham gia slot cuối cùng cùng lúc:
→ Dùng database transaction với SELECT ... FOR UPDATE
→ Chỉ 1 người được confirmed, người kia vào waitlist
```

### Business Rules
- Không có confirmation step (join là confirmed ngay)
- User không cần invite để join (nếu game public và còn chỗ)

---

## F3. Waitlist

### Acceptance Criteria
- [ ] Waitlist có thứ tự FIFO (first in, first out)
- [ ] Khi có chỗ trống → auto-promote người đầu waitlist
- [ ] Người được promote nhận notification ngay
- [ ] Số waitlist không giới hạn

### Auto-Promotion Trigger
- Người rời game (DELETE /community/games/:id/leave)
- Creator xóa người khỏi game
- Invited user từ chối

---

## F4. Lobby

### Acceptance Criteria
- [ ] Default: chỉ hiện game từ hôm nay trở đi, status "open" hoặc "full"
- [ ] Filter: date range, skillLevel, hasSlots (chỉ game còn chỗ)
- [ ] Sort theo khoảng cách nếu user cho phép location
- [ ] MapView: markers tại tọa độ game, cluster khi zoom out
- [ ] Game status = "completed"/"cancelled" không hiện trong lobby

### Search
- Tìm kiếm theo title và location text

---

## F5. Chỉnh Sửa / Xóa Game

### Edit Rules
| Status | Có thể sửa? |
|--------|:-----------:|
| open | ✅ |
| full | ✅ (chỉ description, maxPlayers tăng lên) |
| in_progress | ❌ |
| completed | ❌ |
| cancelled | ❌ |

- Sửa `date` hoặc `location` → gửi notification cho tất cả confirmed
- Tăng maxPlayers → có thể promote người từ waitlist tự động
- Giảm maxPlayers → không được xuống dưới số người đang confirmed

### Delete Rules
- Chỉ Creator xóa được
- Status "in_progress" trở đi → không xóa được
- Khi xóa → gửi notification "game đã bị hủy" + lý do
