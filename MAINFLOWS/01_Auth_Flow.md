# Auth Flow — Luồng Xác Thực

**Module:** M1 — Auth & Profile | **Phase:** 1

---

## 1. Đăng Ký (Register)

```
User nhập email + password + name
    │
    ▼
POST /auth/register
    │
    ├─[email đã tồn tại]──► 409 Conflict
    │
    ▼
Tạo User (password hash bcrypt cost=12)
    │
    ▼
Tạo EmailVerificationToken (OTP 6 số, hết hạn 15 phút)
    │
    ▼
Gửi email OTP (MailKit SMTP)
    │
    ▼
201 Created → { userId, email, message: "Vui lòng xác thực email" }
    │
    ▼
POST /auth/verify-email (nhập OTP)
    │
    ├─[OTP sai / hết hạn]──► 400 Bad Request
    │
    ▼
User.IsEmailVerified = true
    │
    ▼
200 OK → user có thể đăng nhập
```

**Điều kiện:**
- Email: unique, format hợp lệ
- Password: tối thiểu 8 ký tự, có chữ hoa, số, ký tự đặc biệt
- Rate limit đăng ký: 3 tài khoản/IP/giờ

---

## 2. Đăng Nhập Email/Password

```
User nhập email + password
    │
    ▼
POST /auth/login
    │
    ├─[Rate limit: 5 lần/15 phút/IP]──► 429 Too Many Requests
    │
    ├─[Email chưa xác thực]──► 403 + message "Xác thực email trước"
    │
    ├─[Email không tồn tại / password sai]──► 401 (cùng message, không phân biệt)
    │
    ▼
Tạo:
  - accessToken (JWT, hết hạn 15 phút)
  - refreshToken (random string, hết hạn 7 ngày, lưu DB bảng RefreshTokens)
    │
    ▼
200 OK → { accessToken, refreshToken, user: { id, name, email, avatarUrl } }
```

**JWT Claims:**
```json
{
  "sub": "userId",
  "email": "user@example.com",
  "name": "Nguyễn Văn A",
  "role": "user",
  "iat": 1234567890,
  "exp": 1234568790
}
```

---

## 3. Đăng Nhập OAuth2 (Google / Apple / Facebook)

```
Client nhận OAuth token từ provider
    │
    ▼
POST /auth/social { provider: "google", token: "..." }
    │
    ▼
Backend verify token với Google/Apple/Facebook API
    │
    ├─[Token không hợp lệ]──► 401
    │
    ▼
Tìm UserAuthProvider theo (provider, providerId)
    │
    ├─[Chưa có]──► Tạo User mới + UserAuthProvider (IsEmailVerified = true)
    ├─[Đã có]──► Lấy User hiện tại
    │
    ▼
Tạo accessToken + refreshToken
    │
    ▼
200 OK → { accessToken, refreshToken, user, isNewUser: bool }
```

---

## 4. Refresh Token

```
accessToken hết hạn → Client gọi:
    │
    ▼
POST /auth/refresh { refreshToken: "..." }
    │
    ├─[refreshToken không tồn tại DB]──► 401
    ├─[refreshToken hết hạn]──► 401 (xóa token, force re-login)
    │
    ▼
Tạo accessToken mới (15 phút)
Rotate refreshToken: xóa cũ, tạo mới (7 ngày) — Refresh Token Rotation
    │
    ▼
200 OK → { accessToken, refreshToken }
```

**Lưu ý:** Implement Refresh Token Rotation để bảo mật. Nếu refreshToken cũ bị dùng lại → revoke toàn bộ session.

---

## 5. Đổi Mật Khẩu

```
PUT /auth/password
    │
    ▼
Verify currentPassword
    │
    ├─[Sai]──► 400 "Mật khẩu hiện tại không đúng"
    │
    ▼
Hash newPassword (bcrypt cost=12)
    │
    ▼
Cập nhật password
    │
    ▼
Xóa TẤT CẢ RefreshTokens của user (force re-login trên tất cả thiết bị)
    │
    ▼
200 OK
```

---

## 6. Quên Mật Khẩu (Forgot Password)

```
POST /auth/forgot-password { email }
    │
    ▼
[Luôn trả 200 dù email có tồn tại hay không — chống email enumeration]
    │
    ▼ (nếu email tồn tại)
Tạo PasswordResetToken (hết hạn 1 giờ)
    │
    ▼
Gửi email link reset: /reset-password?token=xxx
    │
    ▼
POST /auth/reset-password { token, newPassword }
    │
    ├─[Token không hợp lệ / hết hạn]──► 400
    │
    ▼
Hash newPassword, lưu, xóa tất cả RefreshTokens
    │
    ▼
200 OK
```

---

## 7. Logout

```
DELETE /auth/logout { refreshToken }
    │
    ▼
Xóa RefreshToken khỏi DB
    │
    ▼
204 No Content
```

Client xóa accessToken + refreshToken khỏi local storage.
