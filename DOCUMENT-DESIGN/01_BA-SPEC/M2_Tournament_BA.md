# BA Spec — M2: Tournament Management

**Module:** M2 — Tournament Management
**Phase:** 1
**Ngày cập nhật:** 2026-03-16
**Phạm vi:** Tạo giải đấu, publish, registration (open/waitlist/close), bracket generation, check-in, start, kết thúc, cancel, tìm kiếm & khám phá giải đấu.

---

## Section 1: Actors & Roles

| Actor | Quyền trong Module Tournament |
|-------|-------------------------------|
| **Guest** (chưa đăng nhập) | Xem danh sách giải đấu public; tìm kiếm giải theo tên/filter; xem chi tiết giải đấu (thông tin chung, số người tham gia, lịch thi đấu) |
| **User** (đã đăng nhập, chưa join giải) | Tất cả của Guest + đăng ký tham gia giải đấu đang mở; vào danh sách chờ (waitlist) khi giải đã đầy |
| **Participant** (đã join giải cụ thể) | Tất cả của User + check-in vào giải; xem bracket và lịch thi đấu của cá nhân; rút khỏi giải (nếu giải chưa `InProgress`) |
| **Organizer** (tạo giải — `tournaments.created_by`) | Tất cả của Participant + tạo và chỉnh sửa giải đấu; publish giải (`Draft` → `Published`); mở/đóng đăng ký; duyệt participants (nếu cần); generate bracket; start giải; mark complete giải; cancel giải (khi giải chưa `InProgress`) |
| **Creator** (system role — được cấp bởi Admin) | Được phép tạo giải đấu mới (sau khi tạo → tự động trở thành Organizer của giải đó) |
| **Admin** (quản trị hệ thống) | Tất cả quyền của Organizer trên mọi giải + force cancel bất kỳ giải ở bất kỳ trạng thái; xem tất cả giải kể cả `Draft` và `Cancelled`; chỉnh sửa bất kỳ giải đấu; can thiệp vào participant status |

> **Ghi chú phân quyền:** Authorization dùng `HasPermission()` pattern. `Organizer` và `Participant` là contextual roles trong tournament — xác định qua `tournaments.created_by` và bảng `participants`.

---

## Section 2: User Stories

| ID | As a... | I want to... | So that... |
|----|---------|--------------|------------|
| US-M2-01 | Creator | Tạo giải đấu mới ở trạng thái Draft | Có thể chuẩn bị thông tin trước khi công bố |
| US-M2-02 | Organizer | Chỉnh sửa thông tin giải đấu (tên, ngày, địa điểm, mô tả) | Cập nhật thông tin khi có thay đổi trước khi giải bắt đầu |
| US-M2-03 | Organizer | Publish giải đấu (Draft → Published) | Giải đấu hiển thị công khai để người chơi đăng ký |
| US-M2-04 | Organizer | Cancel giải đấu | Hủy giải khi có lý do bất khả kháng |
| US-M2-05 | Guest / User | Xem chi tiết một giải đấu | Nắm thông tin trước khi quyết định tham gia |
| US-M2-06 | Organizer | Mở đăng ký (Published → RegistrationOpen) | Cho phép người chơi bắt đầu đăng ký |
| US-M2-07 | User | Đăng ký tham gia giải đấu đang mở | Trở thành Participant và thi đấu |
| US-M2-08 | User | Vào waitlist khi giải đã đầy | Được tự động thăng lên nếu có slot trống |
| US-M2-09 | Participant | Rút khỏi giải đấu trước khi giải bắt đầu | Nhường chỗ cho người khác khi không thể tham dự |
| US-M2-10 | Participant | Check-in vào giải đấu trong cửa sổ check-in | Xác nhận sự hiện diện, chính thức tham dự giải |
| US-M2-11 | Organizer | Start giải đấu (CheckInOpen → InProgress) | Bắt đầu vòng thi đấu chính thức |
| US-M2-12 | Organizer | Mark giải đấu là Completed | Kết thúc giải, chốt kết quả chính thức |
| US-M2-13 | Organizer | Generate bracket sau khi check-in đóng | Tạo lịch thi đấu cho tất cả participants đã check-in |
| US-M2-14 | Participant | Xem bracket của giải đấu | Biết mình thi đấu với ai, ở vòng nào |
| US-M2-15 | Participant | Xem lịch thi đấu cá nhân | Biết cụ thể các trận đấu của mình (ngày giờ, đối thủ) |
| US-M2-16 | Guest / User | Xem danh sách giải đấu đang mở/sắp diễn ra | Khám phá giải phù hợp để tham gia |
| US-M2-17 | Guest / User | Tìm kiếm giải đấu theo tên | Tìm nhanh giải đã biết tên |
| US-M2-18 | Guest / User | Lọc giải đấu theo loại, trạng thái, địa điểm, ngày, trình độ | Thu hẹp danh sách phù hợp nhu cầu |
| US-M2-19 | Guest / User | Sắp xếp kết quả tìm kiếm theo ngày/phổ biến | Dễ dàng tìm giải gần nhất hoặc nổi bật nhất |

---

## Section 3: Business Rules

### 3.1 Tạo Giải Đấu

**BR-M2-01** — Chỉ user có system role `Creator` hoặc `Admin` mới được phép tạo giải đấu. User thông thường (`User` role) gọi API tạo giải sẽ nhận `403 Forbidden`.

**BR-M2-02** — Tournament types hỗ trợ:
- `Singles` — đăng ký cá nhân (1v1)
- `Doubles` — đăng ký theo cặp (pair, 2v2). Cả 2 người trong cặp phải là registered users và cùng đăng ký trong một request duy nhất.

**BR-M2-03** — Các trường bắt buộc khi tạo giải đấu:

| Field | Validation |
|-------|-----------|
| `name` | Required, 5–100 ký tự |
| `type` | Required, enum: `Singles` \| `Doubles` |
| `start_date` | Required, phải trong tương lai |
| `location` | Required, tối đa 200 ký tự |
| `min_capacity` | Required, integer |
| `max_capacity` | Required, integer |

**BR-M2-04** — Ràng buộc capacity:
- `min_capacity` >= 4
- `max_capacity` >= `min_capacity`
- `max_capacity` <= 256
- Với `Doubles`: `min_capacity` và `max_capacity` phải là số chẵn (đơn vị tham gia là pair)

**BR-M2-05** — Giải ở trạng thái `Draft` chỉ Organizer và Admin mới xem được. Tất cả các role khác (bao gồm Guest và User) gọi API lấy chi tiết giải `Draft` sẽ nhận `404 Not Found`.

**BR-M2-06** — Điều kiện Publish (`Draft` → `Published`):
- `start_date` phải ít nhất **3 ngày** trong tương lai tính từ thời điểm publish
- `registration_deadline` phải trước `start_date` ít nhất **1 ngày**
- Tất cả required fields (BR-M2-03) phải đã điền đầy đủ

---

### 3.2 Registration

**BR-M2-07** — Người dùng chỉ có thể đăng ký tham gia khi tournament ở trạng thái `RegistrationOpen`. Gọi API đăng ký ở các trạng thái khác sẽ nhận `422 Unprocessable Entity`.

**BR-M2-08** — Auto Full: Khi số participants đã `Registered` đạt `max_capacity`, tournament tự động chuyển sang trạng thái `RegistrationFull`. Mọi đăng ký mới sau đó sẽ được xếp vào waitlist (trạng thái participant: `Waitlisted`).

**BR-M2-09** — Waitlist Auto-Promote: Khi một participant `Registered` rút lui (trạng thái chuyển thành `Withdrawn`), hệ thống tự động:
1. Promote người đứng đầu waitlist (theo thứ tự `joined_at`) lên trạng thái `Registered`
2. Gửi notification cho người được promote
3. Nếu slot vừa trống khiến count < `max_capacity`, tournament status chuyển lại `RegistrationOpen`

**BR-M2-10** — Conflict check: User chỉ được join một giải tại một thời điểm nếu lịch thi đấu trùng nhau. Hai giải được coi là trùng lịch nếu khoảng `[start_date, end_date]` của chúng overlap. Hệ thống kiểm tra trước khi cho phép đăng ký.

**BR-M2-11** — Doubles pair registration: Cả 2 người trong một pair phải:
- Là registered users (có tài khoản hệ thống)
- Cùng đăng ký trong một request (không thể đăng ký từng người rồi ghép sau)
- Chưa đăng ký giải này dưới bất kỳ hình thức nào

**BR-M2-12** — Rút lui (Withdraw): Participant chỉ được rút khỏi giải khi tournament chưa ở trạng thái `InProgress` hoặc `Completed`. Gọi API rút lui khi tournament đang `InProgress` hoặc `Completed` sẽ nhận `422 Unprocessable Entity`.

---

### 3.3 Tournament Lifecycle

**BR-M2-13** — Check-in window: Cửa sổ check-in mở tự động **2 giờ trước** `start_date` (tournament chuyển sang `CheckInOpen`). Cửa sổ đóng khi Organizer start tournament (chuyển sang `InProgress`).

**BR-M2-14** — NoShow: Participant `Registered` không thực hiện check-in trước khi tournament start sẽ tự động bị đánh dấu `NoShow`. Slot của họ được xem như trống và hệ thống kiểm tra waitlist để promote (theo BR-M2-09). Participant `NoShow` không được đưa vào bracket.

**BR-M2-15** — Điều kiện Start: Tournament chỉ có thể chuyển sang `InProgress` khi số participants ở trạng thái `CheckedIn` >= `min_capacity`. Nếu không đủ, Organizer nhận `422` với message rõ ràng.

**BR-M2-16** — Cancel rules:
- Organizer có thể cancel tournament ở bất kỳ trạng thái nào **ngoại trừ** `InProgress` và `Completed`
- Khi tournament đã `InProgress`, chỉ **Admin** mới có quyền cancel
- `Completed` không thể cancel

**BR-M2-17** — Tournament hoàn thành (`Completed`) khi:
- Organizer mark complete một cách thủ công, **hoặc**
- Tất cả matches trong bracket đều có kết quả (status `Completed` hoặc `Walkover`)

---

### 3.4 Bracket

**BR-M2-18** — Bracket formats được hỗ trợ:
- `SingleElimination` — loại trực tiếp
- `RoundRobin` — vòng tròn

Organizer chọn `bracket_format` khi tạo giải. Không thể thay đổi sau khi bracket được generate.

**BR-M2-19** — Generate bracket: Bracket chỉ được generate sau khi check-in window đóng (khi Organizer nhấn Start hoặc sau `start_date`). Thành phần bracket dựa trên danh sách participants có trạng thái `CheckedIn`. Participants `NoShow`, `Withdrawn` không được đưa vào bracket.

**BR-M2-20** — Sau khi bracket đã được generate (tournament ở trạng thái `InProgress`), không thể thêm hoặc bớt participants. Mọi thay đổi danh sách bị từ chối với `422 Unprocessable Entity`.

---

### 3.5 Discovery & Search

**BR-M2-21** — Visibility public: Chỉ những tournaments ở các trạng thái sau mới hiển thị trong danh sách public và kết quả tìm kiếm:
- `Published`, `RegistrationOpen`, `RegistrationFull`, `RegistrationClosed`, `CheckInOpen`, `InProgress`, `Completed`

Tournaments ở trạng thái `Draft` và `Cancelled` **không** hiển thị public (ẩn với Guest/User; Admin vẫn thấy).

**BR-M2-22** — Filter options:

| Filter | Loại | Mô tả |
|--------|------|-------|
| `type` | enum | `Singles` \| `Doubles` |
| `status` | enum (multi-select) | Lọc theo trạng thái giải |
| `location` | text | Tìm kiếm text trong trường location |
| `date_from` | date | start_date >= date_from |
| `date_to` | date | start_date <= date_to |
| `skill_level` | decimal | Lọc theo skill level tối thiểu/tối đa của giải |

**BR-M2-23** — Sort options:

| Sort key | Chiều | Mô tả |
|----------|-------|-------|
| `start_date` | `asc` / `desc` | Sắp xếp theo ngày thi đấu |
| `created_at` | `desc` | Mới nhất trước (default) |
| `participants_count` | `desc` | Phổ biến nhất (nhiều người tham gia nhất) |

**BR-M2-24** — Pagination:
- Mặc định: 20 items/page
- Tối đa: 100 items/page
- Sử dụng cursor-based hoặc offset pagination
- Response phải include `total_count` và `has_next_page`

---

## Section 4: Acceptance Criteria

### AC-M2-01 — Tạo tournament thành công (Creator role)

**Given** user có system role `Creator` và đã đăng nhập
**When** gọi `POST /api/tournaments` với đầy đủ required fields hợp lệ
**Then**
- Response `201 Created` với tournament object
- `status` = `Draft`
- `created_by` = userId của người tạo
- Tournament chỉ hiển thị cho Organizer và Admin, không hiển thị public

---

### AC-M2-02 — Tạo tournament thất bại (User thường không có quyền)

**Given** user có system role `User` (chưa được upgrade lên Creator) và đã đăng nhập
**When** gọi `POST /api/tournaments`
**Then**
- Response `403 Forbidden`
- Body: `{ "error": "Insufficient permissions. Creator role required." }`
- Không có tournament nào được tạo

---

### AC-M2-03 — Publish tournament thành công

**Given** Organizer có tournament ở trạng thái `Draft` với `start_date` là 5 ngày tới, `registration_deadline` là 2 ngày tới, và tất cả required fields đã điền
**When** gọi `PUT /api/tournaments/{id}/publish`
**Then**
- Response `200 OK`
- Tournament `status` chuyển thành `Published`
- Tournament xuất hiện trong danh sách public

---

### AC-M2-04 — Publish thất bại (start_date quá gần)

**Given** Organizer có tournament ở trạng thái `Draft` với `start_date` là ngày mai (ít hơn 3 ngày)
**When** gọi `PUT /api/tournaments/{id}/publish`
**Then**
- Response `422 Unprocessable Entity`
- Body chứa message: `"start_date phải ít nhất 3 ngày trong tương lai"`
- Tournament vẫn ở trạng thái `Draft`

---

### AC-M2-05 — Đăng ký tham gia thành công

**Given** User đã đăng nhập, tournament ở trạng thái `RegistrationOpen`, còn slot trống, và User chưa có lịch trùng
**When** gọi `POST /api/tournaments/{id}/register`
**Then**
- Response `201 Created`
- Participant record tạo với `status` = `Registered`
- `current_capacity` của tournament tăng thêm 1
- User nhận notification xác nhận đăng ký thành công

---

### AC-M2-06 — Đăng ký khi full → vào waitlist

**Given** User đã đăng nhập, tournament ở trạng thái `RegistrationFull` (đã đạt `max_capacity`)
**When** gọi `POST /api/tournaments/{id}/register`
**Then**
- Response `201 Created` (không phải error — đây là expected behavior)
- Participant record tạo với `status` = `Waitlisted`
- `waitlist_position` được gán theo thứ tự FIFO
- User nhận notification thông báo đang trong waitlist và vị trí của mình

---

### AC-M2-07 — Auto-promote từ waitlist khi có slot trống

**Given** Tournament ở trạng thái `RegistrationFull`, có 1 participant `Waitlisted` (position 1)
**When** Một participant `Registered` rút lui (gọi `DELETE /api/tournaments/{id}/participants/me`)
**Then**
- Participant rút lui chuyển sang `Withdrawn`
- Participant trong waitlist (position 1) tự động chuyển sang `Registered`
- Tournament status chuyển về `RegistrationOpen` (nếu count < max_capacity)
- Người được promote nhận notification: "Bạn đã được thăng lên danh sách chính thức"
- Tất cả thay đổi trên xảy ra trong cùng 1 transaction

---

### AC-M2-08 — Rút lui khỏi giải (trước khi InProgress)

**Given** User là Participant `Registered` trong tournament ở trạng thái `RegistrationOpen`
**When** gọi `DELETE /api/tournaments/{id}/participants/me`
**Then**
- Response `200 OK`
- Participant status chuyển thành `Withdrawn`
- Auto-promote waitlist kích hoạt (nếu có người trong waitlist)
- User không còn thấy tournament trong "giải đấu của tôi"

---

### AC-M2-09 — Check-in thành công

**Given** Participant `Registered`, tournament ở trạng thái `CheckInOpen` (trong cửa sổ 2 giờ trước start)
**When** gọi `POST /api/tournaments/{id}/checkin`
**Then**
- Response `200 OK`
- Participant status chuyển thành `CheckedIn`
- `checked_in_at` timestamp được ghi lại

---

### AC-M2-10 — NoShow — không check-in trước deadline

**Given** Participant `Registered` không thực hiện check-in trong cửa sổ check-in
**When** Organizer gọi `POST /api/tournaments/{id}/start` (hoặc hệ thống tự trigger khi cửa sổ check-in hết)
**Then**
- Tất cả participant `Registered` chưa check-in tự động chuyển sang `NoShow`
- Các participants `NoShow` không được đưa vào bracket
- Hệ thống kiểm tra và promote từ waitlist lần cuối (nếu có)
- Participant `NoShow` nhận notification thông báo đã bị đánh dấu NoShow

---

### AC-M2-11 — Start tournament thành công (đủ participants check-in)

**Given** Tournament ở trạng thái `CheckInOpen`, có 8 participants `CheckedIn`, `min_capacity` = 4
**When** Organizer gọi `POST /api/tournaments/{id}/start`
**Then**
- Response `200 OK`
- Tournament status chuyển thành `InProgress`
- Bracket được generate tự động từ 8 participants `CheckedIn`
- Tất cả participants nhận notification "Giải đấu đã bắt đầu"

---

### AC-M2-12 — Start thất bại (không đủ min_capacity check-in)

**Given** Tournament ở trạng thái `CheckInOpen`, có 3 participants `CheckedIn`, `min_capacity` = 4
**When** Organizer gọi `POST /api/tournaments/{id}/start`
**Then**
- Response `422 Unprocessable Entity`
- Body: `{ "error": "Không đủ participants check-in. Cần ít nhất 4, hiện có 3." }`
- Tournament vẫn ở trạng thái `CheckInOpen`

---

### AC-M2-13 — Cancel tournament (bởi Organizer, chưa InProgress)

**Given** Organizer có tournament ở trạng thái `RegistrationOpen`
**When** gọi `PUT /api/tournaments/{id}/cancel` với `{ "reason": "Lý do hủy" }`
**Then**
- Response `200 OK`
- Tournament status chuyển thành `Cancelled`
- Tất cả participants `Registered` và `Waitlisted` nhận notification về việc giải bị hủy kèm lý do
- Tournament không còn xuất hiện trong danh sách public

---

### AC-M2-14 — Search tournaments với filters

**Given** Có nhiều tournaments ở các trạng thái khác nhau trong hệ thống
**When** Guest gọi `GET /api/tournaments?type=Singles&status=RegistrationOpen&location=Hà Nội&page=1&page_size=20`
**Then**
- Response `200 OK`
- Chỉ trả về tournaments thỏa mãn tất cả filters
- Tournaments `Draft` và `Cancelled` không xuất hiện trong kết quả
- Response body có dạng:
  ```json
  {
    "data": [...],
    "total_count": 42,
    "page": 1,
    "page_size": 20,
    "has_next_page": true
  }
  ```

---

## Section 5: State Machine

### 5.1 Tournament Lifecycle

| From State | Event / Trigger | To State | Điều kiện / Ghi chú |
|-----------|----------------|----------|---------------------|
| `Draft` | Organizer publish | `Published` | `start_date` >= now+3d; `registration_deadline` < `start_date`-1d; tất cả required fields đầy đủ |
| `Published` | Organizer mở đăng ký | `RegistrationOpen` | Hành động thủ công của Organizer |
| `RegistrationOpen` | Số participants đạt `max_capacity` | `RegistrationFull` | Auto trigger khi `current_capacity` = `max_capacity` |
| `RegistrationFull` | Participant rút lui, count < max_capacity | `RegistrationOpen` | Auto sau khi auto-promote; nếu vẫn = max_capacity thì giữ nguyên `RegistrationFull` |
| `RegistrationOpen` / `RegistrationFull` | Đến `registration_deadline` | `RegistrationClosed` | Auto trigger theo thời gian |
| `RegistrationClosed` | 2 giờ trước `start_date` | `CheckInOpen` | Auto trigger theo thời gian |
| `CheckInOpen` | Organizer start (đủ điều kiện) | `InProgress` | Số `CheckedIn` >= `min_capacity`; bracket generated tự động |
| `InProgress` | Tất cả matches hoàn thành hoặc Organizer mark complete | `Completed` | Auto khi tất cả matches `Completed`/`Walkover`, hoặc thủ công |
| `Draft` | Organizer/Admin cancel | `Cancelled` | — |
| `Published` | Organizer/Admin cancel | `Cancelled` | — |
| `RegistrationOpen` | Organizer/Admin cancel | `Cancelled` | Notify tất cả participants |
| `RegistrationFull` | Organizer/Admin cancel | `Cancelled` | Notify tất cả participants |
| `RegistrationClosed` | Organizer/Admin cancel | `Cancelled` | Notify tất cả participants |
| `CheckInOpen` | Organizer/Admin cancel | `Cancelled` | Notify tất cả participants |
| `InProgress` | **Chỉ Admin** cancel | `Cancelled` | Organizer không có quyền; notify tất cả participants |

> `Completed` và `Cancelled` là trạng thái terminal — không thể chuyển sang trạng thái khác.

```
Draft
  │  [Publish]
  ▼
Published
  │  [Open Registration]
  ▼
RegistrationOpen ◄──────────────────┐
  │  [max_capacity reached]          │ [participant withdraws, count < max]
  ▼                                  │
RegistrationFull ───────────────────┘
  │
  │ (cả hai → registration_deadline)
  ▼
RegistrationClosed
  │  [2h trước start_date — auto]
  ▼
CheckInOpen
  │  [Organizer start + đủ check-in]
  ▼
InProgress
  │  [All matches done / Organizer complete]
  ▼
Completed

(Mọi trạng thái trước Completed → Cancelled khi Organizer/Admin cancel)
```

---

### 5.2 Participant Registration Status

| From State | Event / Trigger | To State | Ghi chú |
|-----------|----------------|----------|---------|
| — | Đăng ký thành công, còn slot | `Registered` | `joined_at` timestamp ghi lại |
| — | Đăng ký khi tournament `RegistrationFull` | `Waitlisted` | `waitlist_position` được gán theo FIFO |
| `Waitlisted` | Auto-promote (có slot trống) | `Registered` | Notify participant; `promoted_at` timestamp ghi lại |
| `Registered` | Participant thực hiện check-in | `CheckedIn` | Chỉ trong cửa sổ `CheckInOpen`; `checked_in_at` ghi lại |
| `Registered` | Không check-in trước khi tournament start | `NoShow` | Auto; slot được giải phóng cho waitlist |
| `Registered` | Participant tự rút lui | `Withdrawn` | Chỉ khi tournament chưa `InProgress`; trigger auto-promote |
| `Waitlisted` | Participant tự rút lui | `Withdrawn` | Luôn cho phép rút khỏi waitlist |
| `CheckedIn` | Tournament complete | `Completed` | Trạng thái final |

```
                    ┌─────────────┐
Đăng ký (có slot) → │ Registered  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────────┐
              │ [Check-in]  │ [Không check-in] │ [Rút lui]
              ▼            ▼                ▼
         CheckedIn      NoShow         Withdrawn
              │
              │ [Tournament complete]
              ▼
          Completed

Đăng ký (hết slot) → Waitlisted
                          │
              ┌───────────┤
              │ [Promote]  │ [Rút lui]
              ▼            ▼
          Registered   Withdrawn
```

---

*Tài liệu này là nguồn sự thật cho M2 Tournament Management. Mọi thay đổi business rules phải được cập nhật tại đây trước khi implement.*
