# AppPickleball — Kiểm Toán Kiến Trúc Hiện Tại
**Ngày:** 2026-03-16 | **Phiên bản:** 1.0 (Hiện tại)

---

## 📋 Tóm Tắt Tổng Quan

AppPickleball là ứng dụng quản lý giải đấu Pickleball (web + mobile). Hiện tại sử dụng Clean Architecture (.NET 8) với 7 modules, 18 bảng DB, 52 endpoints.

**Phase 1 (Hiện tại):** Auth, Profile, Tournament, Match Scoring, Notification
**Phase 2 (Dự kiến):** Community Game, Chat

---

## 🏗️ Tech Stack Hiện Tại

| Thành phần | Công nghệ | Mục đích |
|-----------|-----------|---------|
| **Backend API** | .NET 8 Web API | REST + SignalR |
| **Database** | PostgreSQL 16 | Lưu trữ dữ liệu chính |
| **Cache** | Redis | Session, xếp hạng, dữ liệu real-time |
| **ORM** | Entity Framework Core 8 | Lớp truy cập dữ liệu |
| **Realtime** | SignalR | Điểm trận đấu, chat, thông báo |
| **Auth** | JWT + Refresh Token + OAuth2 | Xác thực & phân quyền |
| **Storage** | Cloudinary (Miễn phí) | Avatar, banner, hình ảnh |
| **Push Notification** | FCM | Push trên mobile |
| **Web Frontend** | React (Vite) + TypeScript | Ứng dụng web |
| **Mobile** | React Native (Expo) | Ứng dụng iOS/Android |

---

## 📦 Các Module Hiện Tại

```
M1 — Auth & Profile (Phase 1)
├── Đăng ký (email/password + xác thực OTP)
├── Đăng nhập (email/password + OAuth2: Google, Apple, Facebook)
├── Làm mới token + Token Rotation
├── Quản lý hồ sơ
└── Hệ thống theo dõi

M2 — Quản lý Giải Đấu (Phase 1)
├── Tạo giải đấu (Singles/Doubles)
├── Mời người chơi / Chấp nhận yêu cầu
├── Hình thành đội (Doubles)
├── Xếp bảng (Round Robin)
├── Chuyển đổi trạng thái (draft → open → ready → in_progress → completed)
└── Quản lý người tham gia

M3 — Trận Đấu & Tính Điểm (Phase 1)
├── Tạo lịch thi đấu (Round Robin)
├── Ghi lại kết quả trận đấu (Best of 1 / Best of 3)
├── Lịch sử điểm & Kiểm toán
└── Xác định người thắng

M4 — Hệ Thống Thông Báo (Phase 1)
├── Thông báo trong ứng dụng
├── Thông báo push (FCM)
└── Thông báo email

M5 — Game Cộng Đồng (Phase 2)
├── Tạo game giao hữu
└── Tìm & tham gia game

M6 — Chat (Phase 2)
├── Tin nhắn real-time
└── Phòng chat (theo giải đấu)

M7 — Khám Phá & Tìm Kiếm (Phase 1)
├── Duyệt giải đấu
├── Lọc theo loại, ngày, mức độ kỹ năng
└── Xem hồ sơ người chơi
```

---

## 🗄️ Schema Cơ Sở Dữ Liệu (18 Bảng)

### Bảng Phase 1
1. **Users** — Tài khoản người dùng chính
2. **UserAuthProviders** — Các nhà cung cấp OAuth (Google, Apple, Facebook)
3. **RefreshTokens** — Lưu trữ JWT refresh token
4. **Tournaments** — Metadata giải đấu
5. **Participants** — Sự tham gia của người dùng trong giải
6. **Teams** — Đội cho giải đôi
7. **Groups** — Bảng/nhóm cho round robin
8. **GroupMembers** — Thành viên trong mỗi nhóm
9. **Matches** — Các trận đấu riêng lẻ
10. **MatchScoreHistories** — Lịch sử kiểm toán điểm
11. **Notifications** — Thông báo trong ứng dụng
12. **DeviceTokens** — Token FCM cho thông báo push

### Bảng Phase 2
13. **Follows** — Quan hệ theo dõi của người dùng
14. **CommunityGames** — Game giao hữu
15. **GameParticipants** — Người chơi trong game
16. **ChatRooms** — Kênh chat
17. **ChatMembers** — Thành viên phòng chat
18. **Messages** — Tin nhắn chat

---

## 🔐 Auth & Bảo Mật Hiện Tại

### Luồng Auth (Hiện tại)
```
1. Đăng ký
   └─ Email/Password → Xác thực OTP (hết hạn 15 phút)

2. Đăng nhập (Email/Password)
   └─ Xác minh email đã được xác thực
   └─ Kiểm tra 5 lần sai trong 15 phút → khóa 15 phút
   └─ Trả về: accessToken (15 phút) + refreshToken (7 ngày)

3. OAuth2 (Google/Apple/Facebook)
   └─ Xác minh token của nhà cung cấp
   └─ Liên kết hoặc tạo tài khoản
   └─ Trả về: accessToken + refreshToken

4. Làm mới Token
   └─ Triển khai token rotation (token mới, thu hồi cũ)
   └─ Phát hiện sử dụng lại token → thu hồi tất cả phiên người dùng
```

### JWT Claims
```json
{
  "sub": "userId",
  "email": "user@example.com",
  "name": "Tên người dùng",
  "role": "user",
  "iat": 1234567890,
  "exp": 1234568790
}
```

### Quy Tắc Mật Khẩu
- Tối thiểu 8 ký tự
- Ít nhất 1 chữ hoa
- Ít nhất 1 số
- Ít nhất 1 ký tự đặc biệt
- Hash với bcrypt (cost=12)

### Giới Hạn Tốc Độ (Hiện tại)
- **Đăng ký:** 3 tài khoản/IP/giờ
- **Lần đăng nhập sai:** 5 lần/IP/15 phút → khóa 15 phút
- **Gửi lại OTP:** 1 lần/60 giây, tối đa 3 lần → phải đăng ký lại

---

## 🎮 Cơ Chế Giải Đấu (Hiện tại)

### Loại Giải Đấu
- **Singles:** Trận 1v1, 1-4 bảng (4/8/12/16 người chơi)
- **Doubles:** Trận 2v2, 1-2 bảng (8/16 người chơi)

### Luồng Trạng Thái Giải Đấu
```
draft → open → ready → in_progress → completed
         ↓
       cancelled (bất kỳ lúc nào ngoại trừ completed)
```

### Trạng Thái Người Tham Gia
- **invited_pending** — Chờ phản hồi (hết hạn 72 giờ)
- **request_pending** — Người chơi gửi yêu cầu tham gia, chờ phê duyệt
- **confirmed** — Người tham gia đã xác nhận
- **rejected** — Yêu cầu bị từ chối (không thể tham gia lại)
- **withdrawn** — Người tham gia đã rút khỏi
- **completed** — Giải đấu kết thúc

### Tính Điểm Trận Đấu (Hiện tại)
- **Best of 1:** Một trò chơi (người đầu tiên đạt 11)
- **Best of 3:** Best of 3 trò chơi (người đầu tiên đạt 11 cho mỗi trò)
- **Format:** Chỉ Singles/Doubles
- **Round Robin:** Mỗi người chơi/đội chơi với tất cả những người khác một lần

### Ghép Đôi
- Xếp nhóm tự động (Round Robin)
- Doubles: Hình thành đội ngẫu nhiên với sự phê duyệt của người tạo
- Không có seeding dựa trên ELO/kỹ năng (hiện tại)

---

## 📊 Tổng Quan API Hiện Tại

**Tổng Endpoints:** 52

### Các Nhóm Chính
- **Xác thực (8):** Đăng ký, đăng nhập, OAuth, làm mới, đăng xuất, đổi mật khẩu
- **Hồ sơ (6):** Xem/cập nhật hồ sơ, theo dõi/bỏ theo dõi, xem người theo dõi
- **Giải Đấu (16):** CRUD, mời, chấp nhận, từ chối, quản lý trạng thái
- **Người Tham Gia (8):** Quản lý người tham gia, đội, xếp bảng
- **Trận Đấu & Tính Điểm (10):** Tạo trận, ghi điểm, xem kết quả
- **Thông Báo (4):** Xem thông báo, đánh dấu đã đọc

---

## 🔴 Các Vấn Đề & Khoảng Trống Đã Biết

### 1. **Các Mối Lo Ngại Bảo Mật**
- [ ] Không có giới hạn tốc độ trên các endpoint API (chỉ auth)
- [ ] Token JWT được lưu trong localStorage → dễ bị tấn công XSS
- [ ] Cấu hình CORS không được ghi chép
- [ ] Không có lớp xác thực/vệ sinh đầu vào
- [ ] Phát hiện sử dụng lại refresh token được triển khai nhưng cần xác minh
- [ ] Không có ghi nhật ký kiểm toán cho các hoạt động nhạy cảm

### 2. **Các Vấn Đề Auth & Đăng Nhập**
- [ ] OAuth flow không được tối ưu cho mobile (Expo)
- [ ] Xử lý email private relay của Apple không hoàn thành
- [ ] Không có luồng "thay đổi email" với xác minh
- [ ] Luồng đặt lại mật khẩu bị thiếu
- [ ] Khóa tài khoản sau khi thay đổi mật khẩu (thu hồi tất cả phiên) — quá khắt

### 3. **Các Vấn Đề Giải Đấu & Trận Đấu**
- [ ] Không có seeding dựa trên kỹ năng hoặc hệ thống xếp hạng
- [ ] Chỉ Round Robin — không có định dạng bracket/elimination
- [ ] Không có hệ thống bye cho số lượng người tham gia lẻ
- [ ] Không xử lý hòa/tied trong doubles
- [ ] Hình thành đội chỉ giới hạn ở shuffle ngẫu nhiên
- [ ] Không có giải quyết tranh cãi/khiếu nại cho kết quả
- [ ] Logic tạo lịch thi đấu không được chi tiết

### 4. **Dữ Liệu & Hiệu Suất**
- [ ] Không có tài liệu tối ưu hóa truy vấn cơ sở dữ liệu
- [ ] Không có chiến lược caching cho bảng xếp hạng/xếp hạng
- [ ] Không có giới hạn phân trang trên các endpoint danh sách
- [ ] Giao hàng thông báo không có logic retry
- [ ] Khả năng mở rộng chat không được thiết kế (Phase 2)

### 5. **Thử Nghiệm & Tài Liệu**
- [ ] Không có tài liệu thử nghiệm API
- [ ] Không có chiến lược di chuyển schema cơ sở dữ liệu
- [ ] Xử lý ngoại lệ backend không được chuẩn hóa

### 6. **Các Vấn Đề Real-time**
- [ ] Thiết kế hub SignalR không được chi tiết
- [ ] Không có chiến lược fallback kết nối
- [ ] Phát sóng cho các nhóm lớn không được tối ưu

---

## 🎯 Quyết Định Thiết Kế (Hiện tại)

### ✅ Quyết Định Tốt
- Tách biệt Clean Architecture (Domain → App → API → Infrastructure)
- JWT + Refresh Token rotation cho bảo mật
- Máy trạng thái rõ ràng cho trạng thái giải đấu
- Xác thực khả năng (slot cố định)
- Xác minh email trước khi đăng nhập
- Hỗ trợ đa thiết bị (refresh token trên mỗi thiết bị)

### ❌ Quyết Định Có Vấn Đề
- Khả năng cố định (không linh hoạt cho giải đấu)
- Chỉ định dạng Round Robin (không linh hoạt)
- Hình thành đội ngẫu nhiên (không cạnh tranh)
- Liên kết email OAuth không rõ ràng
- Giới hạn tốc độ chỉ trên auth (API không được bảo vệ)
- Không có tài liệu xử lý không đồng bộ (background jobs)

---

## 📝 Cần Thiết Kế Lại

### Ưu Tiên Cao (Người dùng đề cập)
1. **Nâng cấp bảo mật**
   - Thêm giới hạn tốc độ API
   - Triển khai CORS đúng cách
   - Thêm ghi nhật ký kiểm toán
   - Cải thiện bảo mật lưu trữ token

2. **Thiết kế lại Auth & Đăng Nhập**
   - Luồng OAuth tốt hơn (tối ưu cho mobile)
   - Luồng đặt lại mật khẩu
   - Luồng thay đổi email
   - Phục hồi tài khoản

3. **Thiết kế lại Loại Giải Đấu**
   - Hỗ trợ bracket elimination
   - Hỗ trợ hệ thống Swiss
   - Thêm seeding/xếp hạng
   - Khả năng linh hoạt (không slot cố định)
   - Hệ thống bye cho người tham gia lẻ

### Ưu Tiên Trung Bình
4. **Hiệu Suất & Khả Năng Mở Rộng**
   - Tối ưu hóa cơ sở dữ liệu
   - Chiến lược caching
   - Phân trang API
   - Hàng đợi công việc background

5. **Real-time & Thông Báo**
   - Thiết kế hub SignalR
   - Cơ chế retry thông báo
   - Khả năng mở rộng chat (Phase 2)

6. **Thử Nghiệm & Khả Quan Sát**
   - Chiến lược ghi nhật ký
   - Tiêu chuẩn xử lý lỗi
   - Thử nghiệm tích hợp

---

## 🔧 Thứ Tự Xây Dựng Hiện Tại (Kế Hoạch Thực Thi)

### Phase 1 (Hiện tại)
- ✅ Thiết lập Auth & Profile
- ✅ CRUD Giải Đấu
- ✅ Lịch thi đấu (Round Robin)
- ✅ Ghi lại điểm
- ✅ Thông báo
- 🟡 Thử nghiệm & cứng hóa bảo mật (không hoàn thành)

### Phase 2 (Chờ xử lý)
- Game Cộng Đồng
- Hệ thống Chat
- Tính năng nâng cao (bảng xếp hạng, v.v.)

---

## Bảng Tóm Tắt

| Khía Cạnh | Trạng Thái | Ưu Tiên | Vấn Đề |
|-----------|-----------|---------|--------|
| **Kiến Trúc** | ✅ Tốt | 🟡 Trung Bình | Thêm lớp xử lý lỗi |
| **Cơ Sở Dữ Liệu** | ✅ Thiết kế | 🟡 Trung Bình | Cần tối ưu hóa |
| **Auth/Bảo Mật** | 🟡 Từng phần | 🔴 **Cao** | Nhiều khoảng trống |
| **Logic Giải Đấu** | 🟡 Hạn chế | 🔴 **Cao** | Chỉ Round Robin |
| **Thiết Kế API** | 🟡 Cơ bản | 🟡 Trung Bình | Không giới hạn tốc độ |
| **Thử Nghiệm** | ❌ Thiếu | 🟡 Trung Bình | Không có tài liệu thử nghiệm |
| **Real-time** | 🟡 Dự kiến | 🟡 Trung Bình | Không được tối ưu |

---

## Các Bước Tiếp Theo Để Thiết Kế Lại

**Kiểm toán này cho thấy 3 lĩnh vực chính cần thiết kế lại:**

1. **Bảo Mật & Auth** (nền tảng)
2. **Hệ Thống Giải Đấu** (tính năng cơ bản)
3. **Cứng Hóa API** (khả năng mở rộng)

**Khuyến Nghị:** Thiết kế lại theo thứ tự này:
1. Auth & Bảo Mật (ảnh hưởng đến mọi thứ)
2. Loại giải đấu & hệ thống ghép đôi
3. Tiêu chuẩn API & hiệu suất

---

*Tài liệu được tạo vào 2026-03-16 để kiểm duyệt kiến trúc*
