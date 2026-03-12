# Tài Liệu Kỹ Thuật: Đăng Nhập Facebook SSO

## Tổng Quan

AppPickleball hỗ trợ đăng nhập bằng **Facebook OAuth 2.0** cho cả **Web** và **Mobile**. Hệ thống sử dụng **Token-based Authentication** (JWT AccessToken + RefreshToken).

**Cách tiếp cận:** Client-side token flow — Client (Web hoặc Mobile) dùng Facebook SDK để lấy **Access Token**, sau đó gửi lên Backend API. Backend xác minh với Facebook Graph API, tìm/tạo user, và trả về `AccessToken` + `RefreshToken`.

> [!NOTE]
> **Khác biệt so với Google:** Facebook trả về **Access Token** (opaque string), không phải ID Token (JWT). Backend phải gọi **Graph API** để verify và lấy thông tin user.

> [!WARNING]
> Facebook **không đảm bảo** trả về email — user có thể từ chối cấp quyền email. Hệ thống cần xử lý trường hợp email null.

---

## Kiến Trúc Tổng Quan

### Luồng chung cho cả Web và Mobile

```
┌──────────────────┐     ┌─────────────────────┐     ┌────────────────────┐
│ Client           │     │  AppPickleball API  │     │  Facebook Graph    │
│ (Web / Mobile)   │     │  (ASP.NET Core)     │     │  API               │
└────────┬─────────┘     └──────────┬──────────┘     └─────────┬──────────┘
         │                          │                           │
         │ 1. Facebook Login        │                           │
         │    (SDK)                 │                           │
         │──────────────────────────────────────────────────>   │
         │                          │                           │
         │ 2. Nhận Access Token     │                           │
         │<──────────────────────────────────────────────────   │
         │                          │                           │
         │ 3. POST /api/auth/       │                           │
         │    facebook-login        │                           │
         │    { accessToken }       │                           │
         │─────────────────────────>│                           │
         │                          │                           │
         │                          │ 4. GET /me?fields=        │
         │                          │    id,name,email          │
         │                          │─────────────────────────> │
         │                          │                           │
         │                          │ 5. { id, name, email? }   │
         │                          │<───────────────────────── │
         │                          │                           │
         │                          │ 6. Find/Create User       │
         │                          │    + Link Facebook Account│
         │                          │    + Generate JWT tokens  │
         │                          │                           │
         │ 7. Response JSON:        │                           │
         │    { accessToken,        │                           │
         │      refreshToken,       │                           │
         │      expiresIn, user }   │                           │
         │<─────────────────────────│                           │
```

---

## SỰ KHÁC BIỆT GIỮA WEB VÀ MOBILE

| Đặc điểm | Web | Mobile (Android/iOS) |
|-----------|-----|----------------------|
| **Lấy Access Token** | Facebook JS SDK (`FB.login()`) | Facebook SDK native |
| **Token nhận được** | `accessToken` từ `authResponse` | `accessToken` từ `LoginResult` |
| **API gọi Backend** | `POST /api/auth/facebook-login` | `POST /api/auth/facebook-login` |
| **Request body** | `{ "accessToken": "..." }` | `{ "accessToken": "..." }` |
| **Response** | Lưu token vào `localStorage` / memory | Lưu token vào `SecureStorage` / Keychain |

> [!IMPORTANT]
> **Backend API hoàn toàn giống nhau** cho cả Web và Mobile. Sự khác biệt chỉ nằm ở phía **Client** (cách lấy Access Token từ Facebook).

---

## PHẦN 1: CẤU HÌNH FACEBOOK OAUTH

### 1.1. Facebook Developer Portal

1. Truy cập [Facebook for Developers](https://developers.facebook.com/) → **My Apps** → **Create App**
2. Chọn loại app: **Consumer** hoặc **Business**
3. Vào **Add Product** → Thêm **Facebook Login**
4. Cấu hình **Facebook Login Settings**:

| Platform | Cấu hình |
|----------|----------|
| **Web** | Valid OAuth Redirect URIs (cho JS SDK popup) |
| **Android** | Package Name + Key Hash |
| **iOS** | Bundle ID |

5. Lấy **App ID** và **App Secret** từ **Settings** → **Basic**

### 1.2. appsettings.json

```json
{
  "FacebookAuth": {
    "AppId": "your_facebook_app_id",
    "AppSecret": "your_facebook_app_secret"
  }
}
```

### 1.3. Backend Settings

```csharp
public class FacebookAuthSettings
{
    public string AppId { get; set; } = string.Empty;
    public string AppSecret { get; set; } = string.Empty;
}
```

---

## PHẦN 2: BACKEND API — FACEBOOK LOGIN ENDPOINT

### 2.1. API Endpoint

**`POST /api/auth/facebook-login`**

**Request Body:**
```json
{
  "accessToken": "EAABwzLix..."
}
```

### 2.2. FacebookLoginCommand

```csharp
public record FacebookLoginCommand(string AccessToken) : IRequest<ApiResponse<AuthResponseDto>>;
```

### 2.3. FacebookLoginCommandHandler

```csharp
public class FacebookLoginCommandHandler : IRequestHandler<FacebookLoginCommand, ApiResponse<AuthResponseDto>>
{
    public async Task<ApiResponse<AuthResponseDto>> Handle(
        FacebookLoginCommand request, CancellationToken cancellationToken)
    {
        // 1. Verify Access Token với Facebook Graph API
        using var httpClient = new HttpClient();
        var fbResponse = await httpClient.GetStringAsync(
            $"https://graph.facebook.com/me?fields=id,name,email&access_token={request.AccessToken}");

        var fbUser = JsonSerializer.Deserialize<FacebookUserInfo>(fbResponse);

        if (fbUser == null || string.IsNullOrEmpty(fbUser.Id))
            throw new UnauthorizedException("Facebook access token không hợp lệ");

        var facebookId = fbUser.Id;
        var email = fbUser.Email;          // Có thể NULL
        var name = fbUser.Name;

        // 2. Tìm UserAuthProvider theo Facebook ID
        var authProvider = await _userAuthProviderRepo.FindAsync(
            x => x.Provider == "facebook" && x.ProviderUserId == facebookId);

        User user;
        bool isNewUser = false;

        if (authProvider != null)
        {
            // Case A: Đã link Facebook → Đăng nhập nhanh
            user = await _userRepo.GetByIdAsync(authProvider.UserId);
        }
        else if (!string.IsNullOrEmpty(email))
        {
            // Có email → tìm user theo email
            user = await _userRepo.GetByEmailAsync(email);

            if (user != null)
            {
                // Case B: Email đã tồn tại, chưa link Facebook → Link thêm
                var newProvider = new UserAuthProvider
                {
                    UserId = user.Id,
                    Provider = "facebook",
                    ProviderUserId = facebookId,
                    Email = email,
                    Name = name
                };
                await _userAuthProviderRepo.AddAsync(newProvider);
            }
            else
            {
                // Case C: User hoàn toàn mới (có email)
                isNewUser = true;
                user = new User
                {
                    Email = email.ToLower(),
                    Name = name ?? email,
                    EmailVerified = true,
                    EmailVerifiedAt = DateTime.UtcNow,
                    PasswordHash = null
                };
                await _userRepo.AddAsync(user);
                await CreateAuthProvider(user.Id, facebookId, email, name);
            }
        }
        else
        {
            // Case D: Không có email → Tạo user mới với placeholder email
            isNewUser = true;
            user = new User
            {
                Email = $"fb_{facebookId}@facebook.placeholder",
                Name = name ?? $"Facebook User {facebookId}",
                EmailVerified = false,
                PasswordHash = null
            };
            await _userRepo.AddAsync(user);
            await CreateAuthProvider(user.Id, facebookId, null, name);
        }

        // 3. Generate JWT tokens
        var accessToken = _jwtService.GenerateAccessToken(user);
        var rawRefreshToken = _jwtService.GenerateRefreshToken();
        var refreshToken = new RefreshToken
        {
            UserId = user.Id,
            TokenHash = _jwtService.HashToken(rawRefreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(_authSettings.RefreshTokenExpiryDays)
        };
        await _refreshTokenRepo.AddAsync(refreshToken);
        await _uow.SaveChangesAsync(cancellationToken);

        // 4. Trả về response
        var response = new AuthResponseDto(
            accessToken, rawRefreshToken,
            _authSettings.AccessTokenExpiryMinutes * 60,
            MapUser(user), isNewUser);

        return ApiResponse<AuthResponseDto>.SuccessResponse(
            response, "Đăng nhập Facebook thành công");
    }

    private async Task CreateAuthProvider(Guid userId, string facebookId, string? email, string? name)
    {
        var provider = new UserAuthProvider
        {
            UserId = userId,
            Provider = "facebook",
            ProviderUserId = facebookId,
            Email = email,
            Name = name
        };
        await _userAuthProviderRepo.AddAsync(provider);
    }
}
```

**Response Body:** (giống Google SSO)
```json
{
  "success": true,
  "message": "Đăng nhập Facebook thành công",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "dGhpcyBpcyBh...",
    "expiresIn": 1800,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@gmail.com",
      "name": "Nguyễn Văn A",
      "avatarUrl": null,
      "skillLevel": 3.0,
      "emailVerified": true,
      "createdAt": "2026-03-13T00:00:00Z"
    },
    "isNewUser": true
  }
}
```

---

## PHẦN 3: CLIENT INTEGRATION

### 3.1. Web — Facebook JS SDK

```html
<!-- Load Facebook JS SDK -->
<script async defer crossorigin="anonymous"
  src="https://connect.facebook.net/en_US/sdk.js"></script>

<script>
window.fbAsyncInit = function() {
    FB.init({
        appId: 'YOUR_FACEBOOK_APP_ID',
        cookie: true,
        xfbml: true,
        version: 'v18.0'
    });
};

async function loginWithFacebook() {
    FB.login(async (response) => {
        if (response.authResponse) {
            const accessToken = response.authResponse.accessToken;

            const result = await fetch('https://api.yourapp.com/api/auth/facebook-login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ accessToken })
            });
            const data = await result.json();

            if (data.success) {
                localStorage.setItem('accessToken', data.data.accessToken);
                localStorage.setItem('refreshToken', data.data.refreshToken);

                if (data.data.isNewUser) {
                    window.location.href = '/complete-profile';
                } else {
                    window.location.href = '/dashboard';
                }
            }
        }
    }, { scope: 'email,public_profile' });
}
</script>

<button onclick="loginWithFacebook()">Đăng nhập bằng Facebook</button>
```

### 3.2. Mobile — React Native

```javascript
import { LoginManager, AccessToken } from 'react-native-fbsdk-next';

async function loginWithFacebook() {
    const result = await LoginManager.logInWithPermissions(['email', 'public_profile']);

    if (!result.isCancelled) {
        const tokenData = await AccessToken.getCurrentAccessToken();
        const accessToken = tokenData?.accessToken;

        const response = await fetch('https://api.yourapp.com/api/auth/facebook-login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ accessToken })
        });
        const data = await response.json();

        if (data.success) {
            await SecureStore.setItemAsync('accessToken', data.data.accessToken);
            await SecureStore.setItemAsync('refreshToken', data.data.refreshToken);
        }
    }
}
```

### 3.3. Mobile — Flutter

```dart
final FacebookLogin _facebookLogin = FacebookLogin();

Future<void> signInWithFacebook() async {
  final result = await _facebookLogin.logIn(permissions: [
    FacebookPermission.email,
    FacebookPermission.publicProfile,
  ]);

  if (result.status == FacebookLoginStatus.success) {
    final accessToken = result.accessToken!.tokenString;

    final response = await http.post(
      Uri.parse('https://api.yourapp.com/api/auth/facebook-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken}),
    );

    final data = jsonDecode(response.body);
    if (data['success']) {
      await secureStorage.write(key: 'accessToken', value: data['data']['accessToken']);
      await secureStorage.write(key: 'refreshToken', value: data['data']['refreshToken']);
    }
  }
}
```

---

## PHẦN 4: DATABASE

### Bảng `UserAuthProviders`

| Column | Type | Mô tả |
|--------|------|-------|
| `id` | UUID PK | ID |
| `user_id` | FK → Users | ID user |
| `provider` | VARCHAR(20) | `facebook` |
| `provider_user_id` | VARCHAR(255) | Facebook User ID (bất biến) |
| `email` | VARCHAR(255) | Email từ Facebook (nullable) |
| `name` | VARCHAR(100) | Tên hiển thị |
| `avatar_url` | VARCHAR(500) | NULL (Facebook không cung cấp qua Graph API /me) |
| `created_at` | TIMESTAMPTZ | Thời gian liên kết |

**Constraints:**
- `UNIQUE(provider, provider_user_id)` — 1 Facebook ID chỉ link 1 user
- `UNIQUE(user_id, provider)` — 1 user chỉ link 1 Facebook account

### Bảng `Users` — Khác biệt khi dùng Facebook SSO

| Column | Email registration | Facebook SSO (có email) | Facebook SSO (không email) |
|--------|-------------------|------------------------|---------------------------|
| `email` | Email thật | Facebook email | `fb_{id}@facebook.placeholder` |
| `password_hash` | Hash | **NULL** | **NULL** |
| `email_verified` | FALSE → verify | **TRUE** | **FALSE** |
| `avatar_url` | NULL | NULL | NULL |

---

## PHẦN 5: LUỒNG HOÀN CHỈNH

```
=== WEB ===
1. User click "Đăng nhập bằng Facebook"
   → Facebook JS SDK popup hiện lên

2. User chọn tài khoản Facebook & chấp nhận quyền

3. Facebook trả về Access Token cho Frontend (JS callback)

4. Frontend gọi: POST /api/auth/facebook-login { accessToken: "..." }

5. Backend gọi Graph API verify → Find/Create User
   → Generate AccessToken + RefreshToken

6. Backend trả JSON response
   → Frontend lưu tokens vào localStorage

7. Frontend redirect đến trang chính ✓

=== MOBILE ===
1. User tap "Đăng nhập bằng Facebook"
   → Facebook SDK hiện native login dialog

2. User chọn tài khoản Facebook & chấp nhận quyền

3. SDK trả về Access Token cho app

4. App gọi: POST /api/auth/facebook-login { accessToken: "..." }

5-7. Giống Web, nhưng lưu tokens vào SecureStore/Keychain ✓
```

---

## PHẦN 6: XỬ LÝ CÁC TRƯỜNG HỢP ĐẶC BIỆT

### User không cấp quyền email cho Facebook

```
Facebook trả về: { "id": "123456", "name": "Nguyen Van A" }
                 (không có "email" field)

→ Server tạo user với email = "fb_123456@facebook.placeholder"
→ User có thể cập nhật email thật sau qua PUT /api/users/profile
→ App nên hiện dialog yêu cầu nhập email thật (isNewUser = true)
```

### User đăng ký Email trước → Sau đó đăng nhập Facebook (cùng email)

```
Trước: Users { email: "a@gmail.com", password_hash: "hash" }
Sau:   Users { email: "a@gmail.com", password_hash: "hash" }
       + UserAuthProviders { provider: "facebook", provider_user_id: "fb_123" }

→ User có thể đăng nhập bằng CẢ 2 cách
```

---

## PHẦN 7: SO SÁNH GOOGLE vs FACEBOOK

| Đặc điểm | Google | Facebook |
|----------|--------|----------|
| Token gửi lên Backend | ID Token (JWT) | Access Token (opaque) |
| Backend verify | `GoogleJsonWebSignature.ValidateAsync()` | Graph API `GET /me` |
| Email guarantee | ✅ Luôn có | ❌ Tùy user cấp quyền |
| Avatar từ provider | ✅ Trong payload | ❌ Cần thêm API call |
| NuGet package | `Google.Apis.Auth` | Không cần (dùng `HttpClient`) |

---

## PHẦN 8: TROUBLESHOOTING

| Lỗi | Nguyên nhân | Cách sửa |
|-----|-------------|---------|
| `Invalid access token` | Token hết hạn hoặc sai | Lấy token mới từ Facebook SDK |
| `400 Bad Request` từ Graph API | Access Token bị revoke | User cần đăng nhập lại Facebook |
| User tạo với placeholder email | Facebook không trả email | Bình thường — hiện dialog nhập email |
| CORS error | FE và BE khác domain | Bật CORS + whitelist |
| Token null từ mobile | SDK config sai | Kiểm tra Key Hash (Android) hoặc Bundle ID (iOS) |

---

**Document Version**: 2.0 (Rewritten for AppPickleball token-based auth)
**Last Updated**: 2026-03-13
**Related Documents:**
- [Google_SSO_Login.md](./Google_SSO_Login.md) — Đăng nhập Google SSO
