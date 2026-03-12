# Module 01: Authentication — API Contracts

| Thông tin | Chi tiết |
|-----------|----------|
| **Module** | Authentication |
| **Base URL** | `/api` |
| **Version** | 1.1 |
| **Ngày cập nhật** | 2026-03-13 |
| **Phase** | 1 |
| **Số endpoints** | 11 |
| **DB Tables** | Users, UserAuthProviders, RefreshTokens |

---

## Endpoints Overview

| # | Method | Endpoint | Auth | Rate Limit | Mô tả |
|---|--------|----------|:----:|:----------:|-------|
| 1.1 | POST | `/auth/register` | ❌ | 10/h | Đăng ký tài khoản mới |
| 1.2 | POST | `/auth/login` | ❌ | 5/15min | Đăng nhập bằng email + mật khẩu |
| 1.4 | POST | `/auth/refresh` | ❌ | 30/h | Làm mới access token |
| 1.5 | PUT | `/auth/password` | ✅ Auth | 3/h | Đổi mật khẩu |
| 1.6 | POST | `/auth/send-verification` | ✅ Auth | 3/h | Gửi OTP xác thực email |
| 1.7 | POST | `/auth/verify-email` | ✅ Auth | 5/h | Xác thực email bằng OTP |
| 1.8 | POST | `/auth/forgot-password` | ❌ | 3/h | Quên mật khẩu — gửi OTP reset |
| 1.9 | POST | `/auth/reset-password` | ❌ | 5/h | Đặt lại mật khẩu bằng OTP |
| 1.10 | POST | `/auth/google-login` | ❌ | 10/15min | Đăng nhập bằng Google SSO |
| 1.11 | POST | `/auth/facebook-login` | ❌ | 10/15min | Đăng nhập bằng Facebook SSO |

---

## 1.1. POST /auth/register — Đăng ký tài khoản

### Summary
Tạo tài khoản mới bằng email và mật khẩu. Sau khi đăng ký thành công, trả về cặp JWT tokens để đăng nhập ngay.

### User Story
```
Là một người chơi pickleball mới,
Tôi muốn đăng ký tài khoản trên ứng dụng,
Để có thể tham gia giải đấu và tạo game cộng đồng.

Acceptance Criteria:
- Tôi nhập email, mật khẩu, tên hiển thị
- Hệ thống kiểm tra email chưa được đăng ký
- Hệ thống kiểm tra mật khẩu đủ mạnh
- Sau khi đăng ký thành công, tôi được đăng nhập ngay (nhận JWT)
- Tôi được gán skill level mặc định 3.0
```

### Luồng xử lý

```
Client                          Server                          Database
  │                               │                               │
  │  POST /auth/register          │                               │
  │  {email, password, name}      │                               │
  │──────────────────────────────>│                               │
  │                               │  Validate input               │
  │                               │  (format, password policy)    │
  │                               │                               │
  │                               │  Check email exists?          │
  │                               │──────────────────────────────>│
  │                               │  ❌ email already exists       │
  │  400 {error: email_exists}    │<──────────────────────────────│
  │<──────────────────────────────│                               │
  │                               │                               │
  │                               │  ✅ email available            │
  │                               │<──────────────────────────────│
  │                               │                               │
  │                               │  Hash password (bcrypt)       │
  │                               │  Create User record           │
  │                               │──────────────────────────────>│
  │                               │                               │
  │                               │  Generate JWT access token    │
  │                               │  Generate refresh token       │
  │                               │  Save RefreshToken record     │
  │                               │──────────────────────────────>│
  │                               │                               │
  │  201 {accessToken,            │                               │
  │       refreshToken, user}     │                               │
  │<──────────────────────────────│                               │
```

### Auth & Role

| Yêu cầu | Giá trị |
|---------|---------|
| Authentication | Không yêu cầu (Public) |
| Authorization | Không yêu cầu |
| Rate Limit | 10 requests / giờ / IP |

### Request

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "email": "player@example.com",
  "password": "SecureP@ss123",
  "name": "Nguyễn Văn A"
}
```

| Field | Type | Required | Validation |
|-------|------|:--------:|------------|
| email | string | ✅ | Email hợp lệ (RFC 5322), max 255 ký tự, unique trong hệ thống |
| password | string | ✅ | Tối thiểu 8 ký tự, phải có: 1 chữ hoa, 1 chữ thường, 1 số, 1 ký tự đặc biệt |
| name | string | ✅ | 2-100 ký tự, không chứa ký tự đặc biệt ngoài dấu tiếng Việt |

### Response

**201 Created:**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
    "expiresIn": 900,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "player@example.com",
      "name": "Nguyễn Văn A",
      "avatarUrl": null,
      "skillLevel": 3.0,
      "createdAt": "2026-03-12T14:30:00Z"
    }
  }
}
```

### Error Codes

| HTTP | Error Type | Điều kiện |
|:----:|-----------|-----------|
| 400 | VALIDATION_ERROR | Email format sai, password yếu, name rỗng |
| 400 | EMAIL_ALREADY_EXISTS | Email đã được đăng ký |
| 429 | RATE_LIMIT_EXCEEDED | Vượt quá 10 lần / giờ |

### Business Rules

1. Password được hash bằng bcrypt (cost factor 12) trước khi lưu
2. Access token có thời hạn 15 phút
3. Refresh token có thời hạn 7 ngày, lưu hash vào DB
4. Skill level mặc định = 3.0
5. Không gửi email xác nhận ở Phase 1 (sẽ thêm Phase 3)

---

## 1.2. POST /auth/login — Đăng nhập

### Summary
Xác thực người dùng bằng email và mật khẩu, trả về cặp JWT tokens.

### User Story
```
Là một người dùng đã có tài khoản,
Tôi muốn đăng nhập vào ứng dụng,
Để truy cập các tính năng (giải đấu, community, chat).

Acceptance Criteria:
- Tôi nhập email và mật khẩu đã đăng ký
- Nếu đúng, tôi nhận được access token + refresh token
- Nếu sai, tôi nhận thông báo lỗi chung (không tiết lộ email có tồn tại hay không)
- Sau 5 lần sai liên tiếp, tài khoản bị khóa tạm 15 phút
```

### Luồng xử lý

```
Client                          Server                          Database
  │                               │                               │
  │  POST /auth/login             │                               │
  │  {email, password}            │                               │
  │──────────────────────────────>│                               │
  │                               │  Find user by email           │
  │                               │──────────────────────────────>│
  │                               │                               │
  │                               │  User not found?              │
  │  401 {error}                  │  → Return generic error       │
  │<──────────────────────────────│  (không tiết lộ email tồn tại)│
  │                               │                               │
  │                               │  Check rate limit             │
  │                               │  (5 attempts / 15 min)        │
  │  429 {error}                  │  → Exceeded?                  │
  │<──────────────────────────────│                               │
  │                               │                               │
  │                               │  Verify password (bcrypt)     │
  │                               │  ❌ wrong → increment counter  │
  │  401 {error}                  │                               │
  │<──────────────────────────────│                               │
  │                               │                               │
  │                               │  ✅ correct                    │
  │                               │  Reset attempt counter        │
  │                               │  Generate tokens              │
  │                               │  Save refresh token → DB      │
  │                               │──────────────────────────────>│
  │                               │                               │
  │  200 {accessToken,            │                               │
  │       refreshToken, user}     │                               │
  │<──────────────────────────────│                               │
```

### Auth & Role

| Yêu cầu | Giá trị |
|---------|---------|
| Authentication | Không yêu cầu (Public) |
| Rate Limit | 5 requests / 15 phút / IP |

### Request

**Body:**
```json
{
  "email": "player@example.com",
  "password": "SecureP@ss123"
}
```

| Field | Type | Required | Validation |
|-------|------|:--------:|------------|
| email | string | ✅ | Email hợp lệ |
| password | string | ✅ | Không rỗng |

### Response

**200 OK:**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "dGhpcyBpcyBhIHJl...",
    "expiresIn": 900,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "player@example.com",
      "name": "Nguyễn Văn A",
      "avatarUrl": "https://s3.../avatar.webp",
      "skillLevel": 3.5,
      "createdAt": "2026-01-15T08:30:00Z"
    }
  }
}
```

### Error Codes

| HTTP | Error Type | Điều kiện |
|:----:|-----------|-----------|
| 401 | INVALID_CREDENTIALS | Email hoặc mật khẩu không đúng (message chung, không tiết lộ chi tiết) |
| 429 | RATE_LIMIT_EXCEEDED | Quá 5 lần thất bại / 15 phút |

### Business Rules

1. **Không tiết lộ** email có tồn tại hay không — luôn trả message chung "Email hoặc mật khẩu không đúng"
2. Sau 5 lần sai: khóa login cho IP đó trong 15 phút
3. Login thành công: reset bộ đếm thất bại
4. Mỗi lần login tạo refresh token mới (multi-device support)

---

## 1.10. POST /auth/google-login — Đăng nhập bằng Google SSO

### Summary
Xác thực Google ID Token từ client SDK (Web GIS / React Native Expo / Flutter). Backend verify với Google, tự động tạo tài khoản nếu chưa tồn tại, liên kết Google account vào `UserAuthProviders`.

> **Khác với login email/password:** Luồng register + login gộp làm một. Nếu email chưa có tài khoản → tự động tạo + liên kết. Nếu đã có → link thêm Google provider (nếu chưa link).

### User Story
```
Là một người dùng mới,
Tôi muốn đăng nhập nhanh bằng tài khoản Google,
Để không phải nhớ thêm mật khẩu mới.

Acceptance Criteria:
- Tôi nhấn nút "Đăng nhập bằng Google" trên ứng dụng
- Google SDK trả về ID Token cho app
- App gửi ID Token lên server
- Server verify với Google, tìm/tạo user, trả về JWT
- Nếu tài khoản mới (isNewUser = true) → app redirect đến màn hình hoàn thiện hồ sơ
```

### Luồng xử lý

```
Client (Web/Mobile)          AppPickleball API           Google OAuth
  │                               │                           │
  │ 1. Google Sign-In (SDK)       │                           │
  │──────────────────────────────────────────────────────────>│
  │                               │                           │
  │ 2. Nhận ID Token              │                           │
  │<──────────────────────────────────────────────────────────│
  │                               │                           │
  │ 3. POST /auth/google-login    │                           │
  │    { idToken }                │                           │
  │──────────────────────────────>│                           │
  │                               │ 4. GoogleJsonWebSignature │
  │                               │    .ValidateAsync()       │
  │                               │──────────────────────────>│
  │                               │ 5. { sub, email, name,    │
  │                               │    picture }              │
  │                               │<──────────────────────────│
  │                               │                           │
  │                               │ 6. Find/Create User       │
  │                               │    + Link GoogleProvider  │
  │                               │    + Generate JWT tokens  │
  │                               │                           │
  │ 7. 200 { accessToken,         │                           │
  │         refreshToken,         │                           │
  │         expiresIn, user,      │                           │
  │         isNewUser }           │                           │
  │<──────────────────────────────│                           │
```

### Auth & Role

| Yêu cầu | Giá trị |
|---------|---------|
| Authentication | Không yêu cầu (Public) |
| Rate Limit | 10 requests / 15 phút / IP |

### Request

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6..."
}
```

| Field | Type | Required | Validation |
|-------|------|:--------:|------------|
| idToken | string | ✅ | Google ID Token (JWT) từ Google Sign-In SDK. Audience phải khớp với `GoogleAuth.ClientId` |

### Response

**200 OK:**
```json
{
  "success": true,
  "message": "Đăng nhập Google thành công",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "dGhpcyBpcyBhIHJl...",
    "expiresIn": 900,
    "isNewUser": false,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "player@gmail.com",
      "name": "Nguyễn Văn A",
      "avatarUrl": "https://lh3.googleusercontent.com/photo.jpg",
      "skillLevel": 3.0,
      "emailVerified": true,
      "createdAt": "2026-03-13T00:00:00Z"
    }
  }
}
```

| Field | Type | Mô tả |
|-------|------|-------|
| isNewUser | bool | `true` nếu tài khoản vừa được tạo → client redirect onboarding |

### Error Codes

| HTTP | Error Type | Điều kiện |
|:----:|-----------|-----------|
| 401 | UNAUTHORIZED | ID Token không hợp lệ, hết hạn, sai audience |

### Business Rules

1. Backend verify ID Token bằng `GoogleJsonWebSignature.ValidateAsync()` với `ClientId` từ config
2. Nếu đã có `UserAuthProvider(provider="google", providerUserId=sub)` → Case A: Đăng nhập nhanh
3. Nếu email đã tồn tại nhưng chưa link Google → Case B: Link thêm Google provider
4. Nếu email chưa tồn tại → Case C: Tạo user mới (`EmailVerified = TRUE`, `PasswordHash = NULL`)
5. `isNewUser = true` để FE biết cần hiển thị màn hình hoàn thiện hồ sơ
6. User tạo qua Google được `EmailVerified = TRUE` tự động (Google đã xác thực email)
7. Cần khai báo trong `appsettings.json`: `GoogleAuth.ClientId`

---

## 1.11. POST /auth/facebook-login — Đăng nhập bằng Facebook SSO

### Summary
Xác thực Facebook Access Token từ client SDK (Web JS SDK / React Native / Flutter). Backend gọi Facebook Graph API để verify, tự động tạo tài khoản nếu chưa tồn tại.

> **Khác với Google:** Facebook trả về Access Token (opaque string), không phải ID Token (JWT). Backend phải gọi `GET /me` để lấy thông tin user. **Facebook không đảm bảo trả email** — user có thể từ chối cấp quyền.

### User Story
```
Là một người dùng mới,
Tôi muốn đăng nhập bằng tài khoản Facebook,
Để không phải tạo thêm mật khẩu.

Acceptance Criteria:
- Tôi nhấn nút "Đăng nhập bằng Facebook" trên ứng dụng
- Facebook SDK trả về Access Token cho app
- App gửi Access Token lên server
- Server verify với Graph API, tìm/tạo user, trả về JWT
- Nếu Facebook không cung cấp email → tài khoản được tạo với placeholder email
```

### Luồng xử lý

```
Client (Web/Mobile)          AppPickleball API           Facebook Graph API
  │                               │                           │
  │ 1. Facebook Login (SDK)       │                           │
  │──────────────────────────────────────────────────────────>│
  │                               │                           │
  │ 2. Nhận Access Token          │                           │
  │<──────────────────────────────────────────────────────────│
  │                               │                           │
  │ 3. POST /auth/facebook-login  │                           │
  │    { accessToken }            │                           │
  │──────────────────────────────>│                           │
  │                               │ 4. GET /me?fields=        │
  │                               │    id,name,email          │
  │                               │    &access_token={token}  │
  │                               │──────────────────────────>│
  │                               │ 5. { id, name, email? }   │
  │                               │<──────────────────────────│
  │                               │                           │
  │                               │ 6. Find/Create User       │
  │                               │    + Link FbProvider      │
  │                               │    + Generate JWT tokens  │
  │                               │                           │
  │ 7. 200 { accessToken, ... }   │                           │
  │<──────────────────────────────│                           │
```

### Auth & Role

| Yêu cầu | Giá trị |
|---------|---------|
| Authentication | Không yêu cầu (Public) |
| Rate Limit | 10 requests / 15 phút / IP |

### Request

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "accessToken": "EAABwzLixFW8BO..."
}
```

| Field | Type | Required | Validation |
|-------|------|:--------:|------------|
| accessToken | string | ✅ | Facebook User Access Token từ Facebook SDK |

### Response

**200 OK:**
```json
{
  "success": true,
  "message": "Đăng nhập Facebook thành công",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "dGhpcyBpcyBhIHJl...",
    "expiresIn": 900,
    "isNewUser": true,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@gmail.com",
      "name": "Nguyễn Văn A",
      "avatarUrl": null,
      "skillLevel": 3.0,
      "emailVerified": true,
      "createdAt": "2026-03-13T00:00:00Z"
    }
  }
}
```

> **Lưu ý:** Nếu Facebook không cung cấp email, `user.email` sẽ là `fb_{facebookId}@facebook.placeholder`. Client nên hiện dialog yêu cầu nhập email thật khi `isNewUser = true`.

### Error Codes

| HTTP | Error Type | Điều kiện |
|:----:|-----------|-----------|
| 401 | UNAUTHORIZED | Access Token không hợp lệ, hết hạn, hoặc bị revoke |

### Business Rules

1. Backend gọi `GET https://graph.facebook.com/me?fields=id,name,email&access_token={token}` để verify
2. Nếu đã có `UserAuthProvider(provider="facebook", providerUserId=fbId)` → Case A: Đăng nhập nhanh
3. Nếu có email và email đã tồn tại nhưng chưa link Facebook → Case B: Link thêm provider
4. Nếu có email và email chưa tồn tại → Case C: Tạo user mới (`EmailVerified = TRUE`)
5. Nếu Facebook **không trả email** → Case D: Tạo user với `email = "fb_{id}@facebook.placeholder"`, `EmailVerified = FALSE`
6. `isNewUser = true` để FE biết cần hiển thị màn hình hoàn thiện hồ sơ + nhập email thật (Case D)
7. Cần khai báo trong `appsettings.json`: `FacebookAuth.AppId`, `FacebookAuth.AppSecret`

---

## 1.4. POST /auth/refresh — Làm mới Access Token

### Summary
Cấp lại access token mới bằng refresh token khi access token hết hạn.

### User Story
```
Là một người dùng đang sử dụng ứng dụng,
Khi access token hết hạn (sau 15 phút),
Tôi muốn hệ thống tự động làm mới token,
Để không bị gián đoạn khi đang sử dụng.

Acceptance Criteria:
- Client tự phát hiện access token sắp hết hạn
- Client gọi API refresh với refresh token
- Nhận access token mới + refresh token mới (rotation)
- Refresh token cũ bị vô hiệu hóa
- Nếu refresh token đã hết hạn hoặc bị thu hồi → buộc đăng nhập lại
```

### Luồng xử lý

```
Client                          Server                          Database
  │                               │                               │
  │  POST /auth/refresh           │                               │
  │  {refreshToken}               │                               │
  │──────────────────────────────>│                               │
  │                               │  Hash refreshToken            │
  │                               │  Find by hash in DB           │
  │                               │──────────────────────────────>│
  │                               │                               │
  │                               │  Token not found?             │
  │  401 {error}                  │  → INVALID                    │
  │<──────────────────────────────│                               │
  │                               │                               │
  │                               │  Token expired?               │
  │  401 {error}                  │  → EXPIRED                    │
  │<──────────────────────────────│                               │
  │                               │                               │
  │                               │  Token already revoked?       │
  │                               │  → REUSE DETECTED!            │
  │                               │  Revoke ALL tokens of user    │
  │                               │──────────────────────────────>│
  │  401 {error: reuse_detected}  │  (Security: force re-login)   │
  │<──────────────────────────────│                               │
  │                               │                               │
  │                               │  ✅ Token valid                │
  │                               │  Revoke old token             │
  │                               │  Generate new token pair      │
  │                               │  Save new refresh token       │
  │                               │──────────────────────────────>│
  │                               │                               │
  │  200 {new accessToken,        │                               │
  │       new refreshToken}       │                               │
  │<──────────────────────────────│                               │
```

### Auth & Role

| Yêu cầu | Giá trị |
|---------|---------|
| Authentication | Không yêu cầu (token trong body) |
| Rate Limit | 30 requests / giờ |

### Request

**Body:**
```json
{
  "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
}
```

### Response

**200 OK:**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "bmV3IHJlZnJlc2ggdG9rZW4...",
    "expiresIn": 900
  }
}
```

### Error Codes

| HTTP | Error Type | Điều kiện |
|:----:|-----------|-----------|
| 401 | INVALID_REFRESH_TOKEN | Token không tồn tại |
| 401 | REFRESH_TOKEN_EXPIRED | Token đã hết hạn (> 7 ngày) |
| 401 | TOKEN_REUSE_DETECTED | Token đã bị thu hồi → nghi ngờ bị đánh cắp → thu hồi TẤT CẢ tokens |

### Business Rules

1. **Token Rotation**: mỗi lần refresh tạo cặp token mới, token cũ bị vô hiệu hóa
2. **Reuse Detection**: nếu refresh token đã bị revoke mà vẫn được sử dụng → đánh cắp token → thu hồi tất cả tokens của user → buộc đăng nhập lại trên mọi thiết bị
3. Refresh token được hash (SHA-256) trước khi lưu DB
4. Background job xóa refresh tokens đã hết hạn hàng ngày

---

## 1.5. PUT /auth/password — Đổi mật khẩu

### Summary
Đổi mật khẩu cho tài khoản hiện tại. Sau khi đổi, tất cả refresh tokens cũ bị thu hồi (force re-login trên các thiết bị khác).

### User Story
```
Là một người dùng đã đăng nhập,
Tôi muốn đổi mật khẩu của mình,
Để bảo vệ tài khoản tốt hơn.

Acceptance Criteria:
- Tôi nhập mật khẩu hiện tại để xác nhận
- Tôi nhập mật khẩu mới (đạt yêu cầu)
- Sau khi đổi thành công, các thiết bị khác bị đăng xuất
- Thiết bị hiện tại vẫn giữ đăng nhập (nhận token mới)
```

### Luồng xử lý

```
Client                          Server                          Database
  │                               │                               │
  │  PUT /auth/password           │                               │
  │  Authorization: Bearer xxx    │                               │
  │  {currentPassword,            │                               │
  │   newPassword}                │                               │
  │──────────────────────────────>│                               │
  │                               │  Extract userId from JWT      │
  │                               │  Get user from DB             │
  │                               │──────────────────────────────>│
  │                               │                               │
  │                               │  Verify currentPassword       │
  │                               │  (bcrypt compare)             │
  │                               │                               │
  │                               │  ❌ Wrong password             │
  │  400 {error}                  │                               │
  │<──────────────────────────────│                               │
  │                               │                               │
  │                               │  ✅ Correct                    │
  │                               │  Validate newPassword policy  │
  │                               │  Hash newPassword (bcrypt)    │
  │                               │  Update user.PasswordHash     │
  │                               │──────────────────────────────>│
  │                               │                               │
  │                               │  Revoke ALL refresh tokens    │
  │                               │  (trừ token hiện tại)         │
  │                               │──────────────────────────────>│
  │                               │                               │
  │  200 {new accessToken,        │                               │
  │       new refreshToken}       │                               │
  │<──────────────────────────────│                               │
```

### Auth & Role

| Yêu cầu | Giá trị |
|---------|---------|
| Authentication | ✅ Bearer Token |
| Authorization | Chỉ user hiện tại (self) |
| Rate Limit | 3 requests / giờ |

### Request

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Body:**
```json
{
  "currentPassword": "OldP@ss123",
  "newPassword": "NewSecureP@ss456"
}
```

| Field | Type | Required | Validation |
|-------|------|:--------:|------------|
| currentPassword | string | ✅ | Không rỗng |
| newPassword | string | ✅ | Tối thiểu 8 ký tự, 1 chữ hoa, 1 chữ thường, 1 số, 1 ký tự đặc biệt. Không trùng currentPassword. |

### Response

**200 OK:**
```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1...",
    "refreshToken": "bmV3IHJlZnJlc2g...",
    "expiresIn": 900
  }
}
```

### Error Codes

| HTTP | Error Type | Điều kiện |
|:----:|-----------|-----------|
| 400 | WRONG_CURRENT_PASSWORD | Mật khẩu hiện tại không đúng |
| 400 | WEAK_PASSWORD | Mật khẩu mới không đạt yêu cầu |
| 400 | SAME_PASSWORD | Mật khẩu mới trùng mật khẩu cũ |
| 401 | UNAUTHORIZED | Chưa đăng nhập |
| 422 | SOCIAL_ACCOUNT | Tài khoản đăng ký qua social, không có mật khẩu |

### Business Rules

1. Mật khẩu mới không được trùng mật khẩu cũ
2. Sau khi đổi: thu hồi tất cả refresh tokens NGOẠI TRỪ token của thiết bị hiện tại
3. Trả về cặp token mới cho thiết bị hiện tại
4. Tài khoản social (Google/Apple) không có password → trả lỗi 422 nếu cố đổi

---

## Tổng kết — Auth Security Notes

| Hạng mục | Chi tiết |
|---------|---------|
| Password hashing | bcrypt, cost factor 12 |
| Access token | JWT HS256, TTL 15 phút |
| Refresh token | Random opaque string, SHA-256 hash lưu DB, TTL 7 ngày |
| Token rotation | Mỗi lần refresh → cặp token mới, token cũ revoke |
| Reuse detection | Token đã revoke bị dùng lại → revoke ALL → force re-login |
| Rate limiting | Login: 5/15min, Register: 10/h, Password: 3/h |
| Brute force | Generic error message, không tiết lộ email tồn tại |
| OAuth Providers | Google (idToken), Apple (idToken), Facebook (accessToken) |
| Multi-provider | 1 user link nhiều providers qua bảng UserAuthProviders |
| Email Verification | OTP 6 số, TTL 10 phút, bắt buộc trước khi tạo giải đấu |

---

## 1.6. POST /auth/send-verification — Gửi OTP xác thực email

### Summary
Gửi mã OTP 6 số qua email để xác thực địa chỉ email của user. Bắt buộc xác thực trước khi tạo giải đấu.

### User Story
```
Là một người dùng đã đăng ký,
Tôi muốn xác thực email của mình,
Để được phép tạo giải đấu trên hệ thống.

Acceptance Criteria:
- Tôi nhấn nút "Xác thực email" trong app
- Hệ thống gửi OTP 6 số về email của tôi
- OTP có hạn 10 phút
- Nếu email đã xác thực rồi → thông báo không cần gửi lại
```

### Auth & Role

| Yêu cầu | Giá trị |
|---------|---------|
| Authentication | ✅ Bearer Token |
| Rate Limit | 3 requests / giờ |

### Request

**Không cần body** — Email lấy từ JWT token của user hiện tại.

### Response

**200 OK:**
```json
{
  "data": {
    "message": "OTP đã được gửi đến email của bạn",
    "expiresInSeconds": 600
  }
}
```

### Error Codes

| HTTP | Error Type | Điều kiện |
|:----:|-----------|-----------|
| 422 | ALREADY_VERIFIED | Email đã được xác thực rồi |
| 429 | RATE_LIMIT_EXCEEDED | Quá 3 lần / giờ |

### Business Rules

1. OTP là 6 chữ số ngẫu nhiên, được hash (SHA-256) trước khi lưu vào `Users.EmailVerificationToken`
2. OTP hết hạn sau 10 phút
3. Mỗi lần gửi OTP mới, OTP cũ bị vô hiệu hóa
4. Nếu user đăng ký qua social (Google/Facebook/Apple) → tự động `EmailVerified = TRUE`

---

## 1.7. POST /auth/verify-email — Xác thực email

### Summary
Xác thực email bằng mã OTP đã gửi. Sau khi thành công, user có thể tạo giải đấu.

### Auth & Role

| Yêu cầu | Giá trị |
|---------|---------|
| Authentication | ✅ Bearer Token |
| Rate Limit | 5 requests / giờ |

### Request

**Body:**
```json
{
  "otp": "482917"
}
```

| Field | Type | Required | Validation |
|-------|------|:--------:|------------|
| otp | string | ✅ | 6 chữ số |

### Response

**200 OK:**
```json
{
  "data": {
    "emailVerified": true,
    "emailVerifiedAt": "2026-03-12T15:30:00Z"
  }
}
```

### Error Codes

| HTTP | Error Type | Điều kiện |
|:----:|-----------|-----------|
| 400 | INVALID_OTP | OTP không đúng |
| 400 | OTP_EXPIRED | OTP đã hết hạn (quá 10 phút) |
| 422 | ALREADY_VERIFIED | Email đã xác thực rồi |

### Business Rules

1. So sánh hash của OTP với `EmailVerificationToken` trong DB
2. Kiểm tra thời gian hết hạn (10 phút kể từ lúc gửi)
3. Sau khi verify thành công: set `EmailVerified = TRUE`, `EmailVerifiedAt = NOW()`, xóa `EmailVerificationToken`
4. Sau 5 lần nhập sai OTP: buộc gửi lại OTP mới
