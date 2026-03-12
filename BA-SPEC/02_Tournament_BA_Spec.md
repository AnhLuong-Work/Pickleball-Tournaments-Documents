# BA Spec — Tournament Management

**Module:** M2 | **Phase:** 1

---

## F1. Tạo Giải Đấu

### Acceptance Criteria
- [ ] Tạo thành công → status = "draft", chưa công khai
- [ ] Số bảng: singles 1–4, doubles 1–2
- [ ] Hiển thị capacity hint: "Cần tối thiểu X người/đội"
- [ ] Cho phép lưu bản nháp (chưa cần điền đủ mọi thứ)

### Validation Rules
| Field | Rule |
|-------|------|
| `name` | Required, 3–200 ký tự |
| `type` | Required: `singles` hoặc `doubles` |
| `numGroups` | Singles: 1–4, Doubles: 1–2 |
| `scoringFormat` | `best_of_1` hoặc `best_of_3` |
| `date` | Nếu có: phải trong tương lai |

### Capacity Rules
| Type | numGroups | Min people | Max people |
|------|:---------:|:----------:|:----------:|
| Singles | 1 | 4 | 4 |
| Singles | 2 | 8 | 8 |
| Singles | 3 | 12 | 12 |
| Singles | 4 | 16 | 16 |
| Doubles | 1 | 8 | 8 |
| Doubles | 2 | 16 | 16 |

*Capacity cố định = numGroups × 4 (singles) hoặc numGroups × 8 (doubles)*

---

## F2. Chỉnh Sửa Giải Đấu

### Fields bị LOCK sau khi có >= 1 confirmed participant
- `type` (singles/doubles) — không thể đổi
- `numGroups` — không thể đổi

### Fields có thể sửa bất kỳ lúc nào (trước completed/cancelled)
- `name`, `description`, `date`, `location`, `bannerUrl`, `scoringFormat`

### Business Rules
- Khi sửa `date` hoặc `location` → gửi notification cho tất cả confirmed participants
- Chỉ Creator mới sửa được

---

## F3. Quản Lý Trạng Thái

### Điều Kiện Chuyển Trạng Thái
| Từ → Đến | Điều kiện |
|----------|-----------|
| `draft` → `open` | Creator publish (không cần điều kiện) |
| `open` → `ready` | confirmed participants = maxCapacity VÀ (doubles: đã ghép đủ đội) VÀ đã xếp bảng xong |
| `ready` → `in_progress` | Creator nhấn "Bắt đầu" (kiểm tra đã tạo lịch đấu) |
| `in_progress` → `completed` | Tự động khi tất cả matches hoàn thành |
| Any (trừ completed) → `cancelled` | Creator hủy |

### Business Rules
- Không cho phép nhảy cóc trạng thái
- `cancelled` → không thể khôi phục

---

## F4. Mời Người Chơi

### Acceptance Criteria
- [ ] Creator tìm kiếm user theo tên/email → chọn → gửi invite
- [ ] Mỗi user chỉ có 1 invite active/giải
- [ ] Invite tạo Participant record { status: "invited_pending" }
- [ ] User nhận push notification + in-app notification
- [ ] User accept/reject trong 72 giờ (sau đó expire)

### Business Rules
- Không thể mời nếu giải đã đủ người (confirmed = maxCapacity)
- Không thể mời user đã có participant record (dù status gì)
- Creator không thể tự mời chính mình (đã là host)

---

## F5. Xin Tham Gia (User)

### Acceptance Criteria
- [ ] Chỉ gửi request khi tournament.status = "open"
- [ ] Giải đã đủ → 422 "Giải đã đủ người"
- [ ] Đã có request pending → 409 "Bạn đã gửi yêu cầu rồi"
- [ ] Creator nhận notification để duyệt

### Business Rules
- 1 user chỉ có 1 request/giải tại bất kỳ thời điểm nào
- User đã bị reject có thể xin lại không? → **Không** (tránh spam)

---

## F6. Duyệt/Từ Chối Request

### Acceptance Criteria
- [ ] Approve: Participant.status = "confirmed", gửi notification "request_approved"
- [ ] Reject: Participant.status = "rejected", gửi notification "request_rejected"
- [ ] Không thể approve nếu giải đã đủ người tại thời điểm duyệt
- [ ] Có thể từ chối kèm lý do (optional, tối đa 200 ký tự)

---

## F7. Ghép Đội (Doubles Only)

### Acceptance Criteria
- [ ] Tất cả confirmed participants phải được ghép thành đội
- [ ] Số người phải chẵn (nếu lẻ → không cho phép ghép)
- [ ] Mỗi người chỉ thuộc 1 đội
- [ ] Random shuffle: hiển thị preview trước khi confirm

### Business Rules
- Chỉ Creator mới ghép được
- Chỉ ghép được khi tournament.status = "open" hoặc "ready" (chưa in_progress)
- Có thể ghép lại nhiều lần trước khi xếp bảng

---

## F8. Xếp Bảng

### Acceptance Criteria
- [ ] Số đơn vị/bảng phải bằng 4 (để Round Robin hoạt động đúng)
- [ ] Tổng số đơn vị = numGroups × 4
- [ ] Sau khi xếp bảng xong → hệ thống tự tạo lịch đấu
- [ ] Random: hiển thị preview trước khi confirm

### Lịch Đấu Được Tạo Tự Động
Mỗi bảng 4 đơn vị → 6 matches, 3 rounds:
```
Round 1: (1 vs 2), (3 vs 4)
Round 2: (1 vs 3), (2 vs 4)
Round 3: (1 vs 4), (2 vs 3)
```
- Match.status = "scheduled"
- Match.round = 1/2/3, Match.matchOrder = 1/2

### Business Rules
- Không thể xếp bảng khi số confirmed participants < maxCapacity (phải đủ người)
- Doubles: phải ghép đội xong trước khi xếp bảng
- Xếp lại bảng → xóa lịch đấu cũ, tạo lại

---

## F9. Rời / Xóa Khỏi Giải

### Player Rời Giải
| Trạng thái giải | Cho phép rời? |
|-----------------|:------------:|
| draft, open | ✅ (tự do) |
| ready | ✅ (nhưng Creator phải xếp lại bảng) |
| in_progress | ❌ (phải dùng walkover) |
| completed, cancelled | ❌ |

### Creator Xóa Người Chơi
- Status = "in_progress" → áp dụng walkover cho các trận chưa diễn ra
- Bắt buộc nhập lý do khi xóa (tối đa 200 ký tự)
- Gửi notification cho người bị xóa
