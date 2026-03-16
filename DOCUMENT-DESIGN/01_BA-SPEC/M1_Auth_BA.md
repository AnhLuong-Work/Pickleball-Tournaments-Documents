# BA Spec — M1: Auth & Profile

**Module:** M1 | **Phase:** 1 | **Ngày cập nhật:** 2026-03-16

---

## Section 1: Actors & Roles

| Actor | Quyền trong module Auth & Profile |
|-------|----------------------------------|
| **Guest** (chưa đăng nhập) | Đăng ký tài khoản email, Đăng nhập email/password, Đăng nhập OAuth (Google/Apple/Facebook), Quên mật khẩu / Reset password |
| **User** (đã đăng nhập) | Đổi mật khẩu, Xem & cập nhật profile của mình, Upload avatar, Logout (revoke token), Refresh access token, Xem profile người khác, **Xem danh sách active sessions**, **Logout tất cả thiết bị**, **Đổi email** |
| **Admin** | Xem danh sách user accounts, Khoá/mở khoá tài khoản, Reset email verification thủ công, **Xem audit log hoạt động của user** |

---

## Section 2: User Stories

| ID | As a... | I want to... | So that... |
|----|---------|-------------|-----------|
| US-M1-01 | Guest | Đăng ký tài khoản bằng email và password | Tôi có thể tạo tài khoản để sử dụng ứng dụng |
| US-M1-02 | Guest (mới đăng ký) | Xác thực email sau khi đăng ký | Tài khoản của tôi được kích hoạt và tôi có thể đăng nhập |
| US-M1-03 | Guest | Đăng nhập bằng email và password | Tôi có thể truy cập vào tài khoản của mình |
| US-M1-04 | Guest | Đăng nhập bằng OAuth (Google / Apple / Facebook) | Tôi có thể đăng nhập nhanh mà không cần nhớ mật khẩu |
| US-M1-05 | User | Tự động refresh access token | Tôi không bị đăng xuất khi đang dùng ứng dụng |
| US-M1-06 | User | Đổi mật khẩu hiện tại | Tôi có thể bảo vệ tài khoản khi nghi ngờ bị lộ |
| US-M1-07 | Guest (quên mật khẩu) | Yêu cầu reset password qua email | Tôi có thể lấy lại quyền truy cập tài khoản |
| US-M1-08 | User | Xem thông tin profile của mình | Tôi biết các thông tin đang được hiển thị công khai |
| US-M1-09 | User | Cập nhật thông tin profile (tên, bio, skill level...) | Tôi có thể duy trì thông tin cá nhân chính xác |
| US-M1-10 | User | Upload ảnh đại diện | Profile của tôi có hình ảnh nhận diện |
| US-M1-11 | User | Đăng xuất khỏi thiết bị hiện tại | Phiên đăng nhập của tôi được chấm dứt an toàn |
| US-M1-12 | Guest | Đăng nhập OAuth bằng email đã có tài khoản email/password | Tôi không bị tạo tài khoản trùng lặp |
| US-M1-13 | User | Xem danh sách thiết bị đang đăng nhập (active sessions) | Tôi có thể phát hiện đăng nhập trái phép |
| US-M1-14 | User | Logout khỏi tất cả thiết bị cùng lúc | Tôi có thể bảo vệ tài khoản khi mất thiết bị |
| US-M1-15 | User | Nhận email thông báo khi tài khoản bị khoá do đăng nhập sai nhiều lần | Tôi biết có người đang cố truy cập tài khoản của mình |
| US-M1-16 | User | Đổi địa chỉ email | Tôi có thể cập nhật thông tin liên lạc khi email cũ không còn dùng |
| US-M1-17 | Admin | Xem audit log hoạt động của từng user | Tôi có thể điều tra các hành vi bất thường |

<!-- FUTURE PHASE — chưa implement trong Phase 1:
| US-M1-F01 | User | Xoá tài khoản vĩnh viễn | ... | (cần quyết định data retention policy trước)
| US-M1-F02 | User | Nhận cảnh báo đăng nhập từ thiết bị/IP lạ | ... | (suspicious login detection)
| US-M1-F03 | User | Bật xác thực 2 yếu tố (2FA) | ... | (TOTP/email OTP)
-->

---

## Section 3: Business Rules

### BR-M1-01: Email Format Validation
- Email phải đúng định dạng RFC 5321 (ví dụ: `user@domain.com`)
- So sánh email theo dạng **case-insensitive** (ví dụ: `TEST@Gmail.com` = `test@gmail.com`)
- Không cho phép email dạng alias có dấu `+` tạo duplicate nếu system muốn enforce — tuỳ config

### BR-M1-02: Password Strength
- Tối thiểu **8 ký tự**
- Phải có ít nhất **1 chữ hoa** (A-Z)
- Phải có ít nhất **1 chữ số** (0-9)
- Phải có ít nhất **1 ký tự đặc biệt** (`!@#$%^&*...`)
- Không được chứa khoảng trắng ở đầu/cuối

### BR-M1-03: Email Must Be Unique
- Mỗi địa chỉ email chỉ tồn tại **1 tài khoản duy nhất** trong hệ thống
- Kiểm tra case-insensitive trước khi tạo tài khoản
- Nếu email đã tồn tại → trả về HTTP 409 với message rõ ràng (không tiết lộ thông tin nhạy cảm)

### BR-M1-04: Email Verification Required
- Sau khi đăng ký thành công → tài khoản ở trạng thái `Unverified`
- **Không thể đăng nhập** khi email chưa được xác thực
- Nếu cố đăng nhập khi chưa verify → trả về HTTP 403 kèm link gửi lại OTP
- OTP gồm **6 chữ số**, hết hạn sau **15 phút**
- Rate limit gửi lại OTP: **tối đa 1 lần / 60 giây**
- Sau **3 lần gửi OTP thất bại** → yêu cầu đăng ký lại

### BR-M1-05: OAuth Account Linking
- Khi user đăng nhập OAuth với email đã tồn tại trong hệ thống (dạng email/password) → **tự động link vào account cũ** (tạo thêm bản ghi `UserAuthProvider`), không tạo tài khoản mới
- Email từ OAuth provider được coi là **đã xác thực** (`isEmailVerified = true`)
- Trường hợp Apple Sign In ẩn email thật → lưu `apple_private_relay_email`, hỏi user cung cấp email thật khi cần
- User đăng ký qua OAuth có thể đặt password sau qua flow "Set Password"

### BR-M1-06: Refresh Token Rotation
- Mỗi lần dùng refresh token để lấy access token mới → hệ thống **issue token mới** và **revoke token cũ ngay lập tức**
- Refresh token chỉ được dùng **đúng 1 lần**
- **Token Reuse Detection:** Nếu một refresh token đã bị revoke được dùng lại → **revoke toàn bộ session của user đó** (tất cả thiết bị) để ngăn chặn tấn công

### BR-M1-07: Token Expiry
- **Access Token TTL:** 15 phút
- **Refresh Token TTL:** 7 ngày
- Mỗi thiết bị có refresh token riêng biệt (multi-device support)
- Đăng nhập trên thiết bị mới **không làm mất session** của thiết bị cũ

### BR-M1-08: Rate Limiting — Login
- Sau **5 lần đăng nhập thất bại liên tiếp** từ cùng IP hoặc cùng account → **khoá 15 phút**
- Khi bị khoá → trả về HTTP 429 với thông tin thời gian unlock
- Đăng nhập thành công → xoá bộ đếm thất bại
- Message lỗi khi sai email/password phải **giống nhau** (không phân biệt để chống user enumeration attack)

### BR-M1-09: Password Reset Token
- Token reset password được gửi qua email dưới dạng link có embedded token
- Token **hết hạn sau 1 giờ**
- Token chỉ dùng được **1 lần** (single-use) — sau khi dùng bị vô hiệu hoá ngay
- Sau khi reset thành công → **revoke tất cả refresh token** (force re-login mọi thiết bị)

### BR-M1-10: Profile Fields
- **Required:** `display_name` (2–100 ký tự, không chỉ có khoảng trắng)
- **Optional:**
  - `bio` — mô tả ngắn, tối đa 500 ký tự
  - `phone_number` — định dạng E.164, private by default
  - `date_of_birth` — không hiển thị công khai, chỉ dùng nội bộ
  - `skill_level` — Enum: `Beginner` | `Intermediate` | `Advanced` | `Pro`
  - `dominant_hand` — `Left` | `Right` | `Ambidextrous`
- **Thông tin công khai:** `display_name`, `avatar_url`, `bio`, `skill_level`
- **Thông tin riêng tư** (chỉ bản thân xem): `email`, `phone_number`, `date_of_birth`

### BR-M1-11: Avatar Upload
- Chỉ chấp nhận định dạng: **JPG / PNG / WEBP**
- Kích thước tối đa: **5MB**
- Ảnh được resize về **256×256 pixels** trước khi lưu trữ (Cloudinary)
- Upload file không đúng định dạng hoặc vượt kích thước → trả về HTTP 422

### BR-M1-12: Logout — Single Device
- Logout chỉ **revoke refresh token của thiết bị hiện tại** (single device logout)
- Các phiên đăng nhập trên thiết bị khác **không bị ảnh hưởng**
- Sau khi logout, access token hiện tại vẫn còn hiệu lực cho đến khi hết 15 phút — client phải tự xoá

### BR-M1-13: Session Management — Active Sessions
- Mỗi lần đăng nhập thành công → tạo 1 `UserSession` record lưu: `device_name`, `device_type` (mobile/web), `ip_address`, `last_active_at`
- User có thể xem danh sách tất cả active sessions của mình
- User có thể **revoke bất kỳ session cụ thể** nào (logout từ xa)
- Sessions không active trong **30 ngày** tự động expired

### BR-M1-14: Logout All Devices
- User có thể revoke **tất cả refresh tokens** của mình (tất cả thiết bị)
- Session hiện tại cũng bị revoke
- Thao tác này yêu cầu **xác nhận password** hiện tại trước khi thực hiện

### BR-M1-15: Account Lock Notification
- Khi tài khoản bị khoá (sau 5 lần fail) → gửi **email thông báo** ngay lập tức
- Email chứa: thời gian bị khoá, IP address của lần đăng nhập fail, link "không phải tôi" để report
- Nếu email chưa verify → **không gửi** (tránh email enumeration)

### BR-M1-16: Email Change
- Yêu cầu nhập **password hiện tại** để xác nhận
- Gửi **OTP xác thực đến email mới** (expire 15 phút)
- Email mới không được **trùng với email của tài khoản khác**
- Sau khi đổi email thành công → **revoke tất cả refresh tokens** (force re-login)
- Email cũ nhận thông báo "email đã được thay đổi"

---

## Section 4: Acceptance Criteria

### AC-M1-01: Đăng Ký Thành Công
```
Given  User nhập email hợp lệ, password đủ mạnh, và display_name
When   POST /api/auth/register
Then   - HTTP 201 Created
       - Tài khoản được tạo với trạng thái Unverified
       - Email xác thực được gửi với OTP 6 chữ số
       - Không trả về password trong response
```

### AC-M1-02: Đăng Ký Thất Bại — Email Đã Tồn Tại
```
Given  Một tài khoản với email "user@example.com" đã tồn tại
When   POST /api/auth/register với email "USER@example.com"
Then   - HTTP 409 Conflict
       - Message: "Email đã được sử dụng"
       - Không tạo tài khoản mới
```

### AC-M1-03: Đăng Ký Thất Bại — Password Yếu
```
Given  User nhập password "abc123" (không có chữ hoa, không có ký tự đặc biệt)
When   POST /api/auth/register
Then   - HTTP 422 Unprocessable Entity
       - Validation errors liệt kê các yêu cầu còn thiếu
```

### AC-M1-04: Đăng Nhập Thành Công
```
Given  Email đã xác thực, password đúng
When   POST /api/auth/login
Then   - HTTP 200 OK
       - Response chứa accessToken (JWT, expire 15 phút)
       - Response chứa refreshToken (opaque, expire 7 ngày)
       - Failed attempt count được reset về 0
```

### AC-M1-05: Đăng Nhập Thất Bại — Sai Password
```
Given  Email tồn tại, nhập password sai
When   POST /api/auth/login
Then   - HTTP 401 Unauthorized
       - Message: "Email hoặc mật khẩu không đúng" (cùng message với sai email)
       - Failed attempt count tăng lên 1
```

### AC-M1-06: Đăng Nhập Bị Khoá — Quá 5 Lần Fail
```
Given  User đã thất bại 5 lần liên tiếp
When   Thử đăng nhập lần thứ 6
Then   - HTTP 429 Too Many Requests
       - Message thông báo tài khoản bị khoá
       - Header chứa thời gian unlock (Retry-After)
       - Khoá kéo dài 15 phút kể từ lần fail thứ 5
```

### AC-M1-07: Email Chưa Verify — Không Thể Đăng Nhập
```
Given  Tài khoản tồn tại nhưng email chưa được xác thực
When   POST /api/auth/login với thông tin đúng
Then   - HTTP 403 Forbidden
       - Message: "Email chưa được xác thực"
       - Response chứa link để gửi lại OTP
```

### AC-M1-08: OAuth Login Lần Đầu — Tạo Account Mới
```
Given  User đăng nhập Google với email chưa tồn tại trong hệ thống
When   POST /api/auth/oauth/google với valid Google token
Then   - HTTP 201 Created
       - Tài khoản mới được tạo với isEmailVerified = true
       - UserAuthProvider record được tạo
       - Trả về accessToken và refreshToken
```

### AC-M1-09: OAuth Login — Email Đã Có Tài Khoản
```
Given  User đã có tài khoản email/password với "user@example.com"
When   Đăng nhập Google với cùng email "user@example.com"
Then   - HTTP 200 OK
       - Không tạo tài khoản mới
       - UserAuthProvider (Google) được thêm vào tài khoản cũ
       - Trả về accessToken và refreshToken của tài khoản cũ
```

### AC-M1-10: Refresh Token Thành Công
```
Given  User có refresh token hợp lệ còn hiệu lực
When   POST /api/auth/refresh với refresh token đó
Then   - HTTP 200 OK
       - Trả về accessToken mới
       - Trả về refreshToken mới
       - Refresh token cũ bị revoke ngay lập tức
```

### AC-M1-11: Refresh Token Reuse — Security Breach
```
Given  Refresh token T1 đã được dùng và đã bị revoke (T2 đang active)
When   POST /api/auth/refresh với token T1 (đã revoke)
Then   - HTTP 401 Unauthorized
       - Toàn bộ session của user (tất cả thiết bị) bị revoke
       - Message: "Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại."
```

### AC-M1-12: Reset Password Thành Công
```
Given  User nhấn link reset password trong email còn hiệu lực (< 1 giờ)
When   POST /api/auth/reset-password với token hợp lệ và password mới đủ mạnh
Then   - HTTP 200 OK
       - Password được cập nhật
       - Tất cả refresh token của user bị revoke (force re-login)
       - Reset token bị vô hiệu hoá
       - Email thông báo "Mật khẩu đã được thay đổi" được gửi
```

### AC-M1-13: Reset Password Token Hết Hạn
```
Given  User nhấn link reset password trong email đã quá 1 giờ
When   POST /api/auth/reset-password với expired token
Then   - HTTP 422 Unprocessable Entity
       - Message: "Link đặt lại mật khẩu đã hết hạn. Vui lòng yêu cầu lại."
       - Không thay đổi password
```

### AC-M1-14: Xem Active Sessions
```
Given  User đang đăng nhập từ 2 thiết bị (web + mobile)
When   GET /api/auth/sessions
Then   - HTTP 200 OK
       - Trả về danh sách 2 sessions với: device_name, device_type, ip_address, last_active_at
       - Session hiện tại được đánh dấu is_current = true
```

### AC-M1-15: Logout Tất Cả Thiết Bị
```
Given  User đang đăng nhập từ 3 thiết bị, nhập đúng password hiện tại
When   POST /api/auth/logout-all với current_password
Then   - HTTP 200 OK
       - Tất cả refresh tokens bị revoke
       - User phải đăng nhập lại trên tất cả thiết bị
```

### AC-M1-16: Account Lock — Gửi Email Thông Báo
```
Given  User (email đã verify) đăng nhập sai lần thứ 5
When   Hệ thống khoá tài khoản
Then   - Email thông báo được gửi đến địa chỉ email của user
       - Email chứa IP address và thời gian khoá
       - Tài khoản bị khoá 15 phút
```

### AC-M1-17: Đổi Email Thành Công
```
Given  User nhập password đúng và email mới chưa tồn tại
When   POST /api/auth/change-email, OTP xác thực được gửi đến email mới và user nhập đúng OTP
Then   - HTTP 200 OK
       - Email được cập nhật
       - Tất cả refresh tokens bị revoke
       - Email cũ nhận thông báo thay đổi
       - Email mới nhận thông báo xác nhận
```

### AC-M1-18: Đổi Email — Email Mới Đã Tồn Tại
```
Given  User nhập email mới đã thuộc tài khoản khác
When   POST /api/auth/change-email
Then   - HTTP 409 Conflict
       - Message: "Email đã được sử dụng"
       - Email không được thay đổi
```

---

## Section 5: State Machines

### 5.1 Email Verification Flow

| From State | Event | To State | Notes |
|-----------|-------|----------|-------|
| `Unverified` | Đăng ký thành công | `PendingVerification` | OTP 6 chữ số, expire 15 phút |
| `PendingVerification` | Click verify / nhập OTP đúng | `Verified` | Token single-use, xoá sau khi dùng |
| `PendingVerification` | OTP hết hạn | `Unverified` | User phải request gửi lại OTP |
| `PendingVerification` | Gửi lại OTP | `PendingVerification` | OTP cũ bị invalidate, tạo OTP mới |
| `Verified` | — (terminal) | — | Có thể đăng nhập |

**Constraints:**
- Rate limit gửi lại OTP: 1 lần / 60 giây
- Sau 3 lần gửi OTP không thành công → yêu cầu đăng ký lại

---

### 5.2 Refresh Token Lifecycle

| From State | Event | To State | Notes |
|-----------|-------|----------|-------|
| `Active` | Dùng để refresh | `Rotated` | Token cũ revoke, token mới issued |
| `Active` | User logout | `Revoked` | Single device logout |
| `Active` | Hết hạn (7 ngày) | `Expired` | Không thể dùng, phải login lại |
| `Active` | Reuse detected (token đã revoke bị dùng lại) | `AllRevoked` | **Toàn bộ session của user bị revoke** |
| `Rotated` | — (terminal) | — | Token mới (Active) đã được issue |
| `Revoked` | — (terminal) | — | Không thể phục hồi |
| `Expired` | — (terminal) | — | User phải login lại |
| `AllRevoked` | — (terminal) | — | Security breach — mọi thiết bị bị đăng xuất |

---

*File này là nguồn chân lý (source of truth) cho business logic module Auth & Profile. Mọi thay đổi requirement cần được cập nhật tại đây trước khi implement.*
