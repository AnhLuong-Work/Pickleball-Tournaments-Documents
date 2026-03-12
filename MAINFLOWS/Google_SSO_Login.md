# Tài Liệu Kỹ Thuật: Đăng Nhập Google SSO

## Tổng Quan

AppPickleball hỗ trợ đăng nhập bằng **Google OAuth 2.0** cho cả **Web** và **Mobile**. Hệ thống sử dụng **Token-based Authentication** (JWT AccessToken + RefreshToken).

**Cách tiếp cận:** Client-side token flow — Client (Web hoặc Mobile) dùng Google SDK/Library để lấy **ID Token** hoặc **Authorization Code**, sau đó gửi lên Backend API. Backend xác minh với Google, tìm/tạo user, và trả về `AccessToken` + `RefreshToken`.

> [!NOTE]
> Luồng này **KHÔNG** dùng ASP.NET middleware server-side redirect. Thay vào đó, Backend expose 1 API endpoint duy nhất `POST /api/auth/google-login` nhận token từ client.

---

## Kiến Trúc Tổng Quan

### Luồng chung cho cả Web và Mobile

```
┌──────────────────┐     ┌─────────────────────┐     ┌─────────────────┐
│ Client           │     │  AppPickleball API  │     │  Google OAuth   │
│ (Web / Mobile)   │     │  (ASP.NET Core)     │     │                 │
└────────┬─────────┘     └──────────┬──────────┘     └────────┬────────┘
         │                          │                          │
         │ 1. Google Sign-In        │                          │
         │    (SDK/Library)         │                          │
         │──────────────────────────────────────────────────> │
         │                          │                          │
         │ 2. Nhận ID Token         │                          │
         │<──────────────────────────────────────────────────  │
         │                          │                          │
         │ 3. POST /api/auth/       │                          │
         │    google-login          │                          │
         │    { idToken }           │                          │
         │─────────────────────────>│                          │
         │                          │                          │
         │                          │ 4. Verify ID Token       │
         │                          │    với Google API         │
         │                          │─────────────────────────>│
         │                          │                          │
         │                          │ 5. Token hợp lệ          │
         │                          │<─────────────────────────│
         │                          │                          │
         │                          │ 6. Find/Create User      │
         │                          │    + Link Google Account  │
         │                          │    + Generate JWT tokens  │
         │                          │                          │
         │ 7. Response JSON:        │                          │
         │    { accessToken,        │                          │
         │      refreshToken,       │                          │
         │      expiresIn, user }   │                          │
         │<─────────────────────────│                          │
```

---

## SỰ KHÁC BIỆT GIỮA WEB VÀ MOBILE

| Đặc điểm | Web | Mobile (Android/iOS) |
|-----------|-----|----------------------|
| **Lấy ID Token** | Google Identity Services (GIS) JS Library | Google Sign-In SDK (native) |
| **Redirect URI** | Không cần (popup hoặc One Tap) | Không cần (SDK xử lý native) |
| **Token nhận được** | `credential` (ID Token JWT) | `idToken` từ `GoogleSignInAccount` |
| **API gọi Backend** | `POST /api/auth/google-login` | `POST /api/auth/google-login` |
| **Request body** | `{ "idToken": "..." }` | `{ "idToken": "..." }` |
| **Response** | Lưu token vào `localStorage` / memory | Lưu token vào `SecureStorage` / Keychain |
| **Gửi token cho API** | `Authorization: Bearer {accessToken}` | `Authorization: Bearer {accessToken}` |

> [!IMPORTANT]
> **Backend API hoàn toàn giống nhau** cho cả Web và Mobile. Sự khác biệt chỉ nằm ở phía **Client** (cách lấy ID Token từ Google).

---

## PHẦN 1: CẤU HÌNH GOOGLE OAUTH

### 1.1. Google Cloud Console

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**
2. Tạo **OAuth 2.0 Client IDs**:

| Platform | Client Type | Ghi chú |
|----------|-------------|---------|
| **Web** | Web application | Cần `Authorized JavaScript origins` |
| **Android** | Android | Cần `Package name` + `SHA-1 fingerprint` |
| **iOS** | iOS | Cần `Bundle ID` |

> [!WARNING]
> Phải tạo **riêng Client ID cho mỗi platform**. Tuy nhiên, tất cả ID Token đều có thể verify bằng **Web Client ID** trên Backend (Google recommend cách này).

### 1.2. appsettings.json

```json
{
  "GoogleAuth": {
    "ClientId": "xxxx.apps.googleusercontent.com",
    "ClientSecret": "GOCSPX-xxxx"
  }
}
```

### 1.3. Backend Configuration

**File:** `AppPickleball.Application/Common/Settings/GoogleAuthSettings.cs`

```csharp
public class GoogleAuthSettings
{
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
}
```

---

## PHẦN 2: BACKEND API — GOOGLE LOGIN ENDPOINT

### 2.1. API Endpoint

**`POST /api/auth/google-login`**

**Request Body:**
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIs..."
}
```

### 2.2. GoogleLoginCommand

```csharp
public record GoogleLoginCommand(string IdToken) : IRequest<ApiResponse<AuthResponseDto>>;
```

### 2.3. GoogleLoginCommandHandler

```csharp
public class GoogleLoginCommandHandler : IRequestHandler<GoogleLoginCommand, ApiResponse<AuthResponseDto>>
{
    public async Task<ApiResponse<AuthResponseDto>> Handle(
        GoogleLoginCommand request, CancellationToken cancellationToken)
    {
        // 1. Verify ID Token với Google
        var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken,
            new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = new[] { _googleSettings.ClientId }
            });

        var googleId = payload.Subject;       // Google User ID (bất biến)
        var email = payload.Email;             // Email (luôn có)
        var name = payload.Name;              // Tên hiển thị
        var picture = payload.Picture;        // Avatar URL

        // 2. Tìm UserAuthProvider theo Google ID
        var authProvider = await _userAuthProviderRepo.FindAsync(
            x => x.Provider == "google" && x.ProviderUserId == googleId);

        User user;
        bool isNewUser = false;

        if (authProvider != null)
        {
            // Case A: Đã link Google → Đăng nhập nhanh
            user = await _userRepo.GetByIdAsync(authProvider.UserId);
        }
        else
        {
            // Tìm user theo email
            user = await _userRepo.GetByEmailAsync(email);

            if (user != null)
            {
                // Case B: Email đã tồn tại, chưa link Google → Link thêm
                var newProvider = new UserAuthProvider
                {
                    UserId = user.Id,
                    Provider = "google",
                    ProviderUserId = googleId,
                    Email = email,
                    Name = name,
                    AvatarUrl = picture
                };
                await _userAuthProviderRepo.AddAsync(newProvider);
            }
            else
            {
                // Case C: User hoàn toàn mới → Tạo mới
                isNewUser = true;
                user = new User
                {
                    Email = email.ToLower(),
                    Name = name ?? email,
                    AvatarUrl = picture,
                    EmailVerified = true,      // Google đã xác thực email
                    EmailVerifiedAt = DateTime.UtcNow,
                    PasswordHash = null         // SSO-only, không có password
                };
                await _userRepo.AddAsync(user);

                var newProvider = new UserAuthProvider
                {
                    UserId = user.Id,
                    Provider = "google",
                    ProviderUserId = googleId,
                    Email = email,
                    Name = name,
                    AvatarUrl = picture
                };
                await _userAuthProviderRepo.AddAsync(newProvider);
            }
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

        // 4. Trả về response (giống Login thường)
        var response = new AuthResponseDto(
            accessToken, rawRefreshToken,
            _authSettings.AccessTokenExpiryMinutes * 60,
            MapUser(user), isNewUser);

        return ApiResponse<AuthResponseDto>.SuccessResponse(
            response, "Đăng nhập Google thành công");
    }
}
```

**Response Body:**
```json
{
  "success": true,
  "message": "Đăng nhập Google thành công",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "dGhpcyBpcyBh...",
    "expiresIn": 1800,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@gmail.com",
      "name": "Nguyễn Văn A",
      "avatarUrl": "https://lh3.googleusercontent.com/...",
      "skillLevel": 3.0,
      "emailVerified": true,
      "createdAt": "2026-03-13T00:00:00Z"
    },
    "isNewUser": false
  }
}
```

---

## PHẦN 3: CLIENT INTEGRATION

### 3.1. Web — Google Identity Services (GIS)

```html
<!-- Load Google GIS Library -->
<script src="https://accounts.google.com/gsi/client" async></script>

<div id="g_id_onload"
     data-client_id="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
     data-callback="handleGoogleSignIn">
</div>
<div class="g_id_signin" data-type="standard"></div>
```

```javascript
// Callback khi user đăng nhập Google thành công
async function handleGoogleSignIn(response) {
    // response.credential = Google ID Token (JWT)
    const result = await fetch('https://api.yourapp.com/api/auth/google-login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken: response.credential })
    });

    const data = await result.json();

    if (data.success) {
        // Lưu tokens
        localStorage.setItem('accessToken', data.data.accessToken);
        localStorage.setItem('refreshToken', data.data.refreshToken);

        // Redirect hoặc cập nhật UI
        if (data.data.isNewUser) {
            window.location.href = '/complete-profile';
        } else {
            window.location.href = '/dashboard';
        }
    }
}
```

### 3.2. Mobile — React Native (Expo)

```javascript
import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';

WebBrowser.maybeCompleteAuthSession();

export function useGoogleLogin() {
    const [request, response, promptAsync] = Google.useIdTokenAuthRequest({
        clientId: 'WEB_CLIENT_ID.apps.googleusercontent.com',        // Web
        androidClientId: 'ANDROID_CLIENT_ID.apps.googleusercontent.com',
        iosClientId: 'IOS_CLIENT_ID.apps.googleusercontent.com',
    });

    useEffect(() => {
        if (response?.type === 'success') {
            const { id_token } = response.params;
            loginWithGoogle(id_token);
        }
    }, [response]);

    async function loginWithGoogle(idToken) {
        const result = await fetch('https://api.yourapp.com/api/auth/google-login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ idToken })
        });
        const data = await result.json();

        if (data.success) {
            // Lưu tokens vào SecureStore
            await SecureStore.setItemAsync('accessToken', data.data.accessToken);
            await SecureStore.setItemAsync('refreshToken', data.data.refreshToken);
        }
    }

    return { promptAsync, request };
}
```

### 3.3. Mobile — Flutter

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

Future<void> signInWithGoogle() async {
  final account = await _googleSignIn.signIn();
  final auth = await account?.authentication;
  final idToken = auth?.idToken;

  if (idToken == null) return;

  final response = await http.post(
    Uri.parse('https://api.yourapp.com/api/auth/google-login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'idToken': idToken}),
  );

  final data = jsonDecode(response.body);
  if (data['success']) {
    // Lưu tokens vào secure storage
    await secureStorage.write(key: 'accessToken', value: data['data']['accessToken']);
    await secureStorage.write(key: 'refreshToken', value: data['data']['refreshToken']);
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
| `provider` | VARCHAR(20) | `google` |
| `provider_user_id` | VARCHAR(255) | Google Subject ID (bất biến) |
| `email` | VARCHAR(255) | Email từ Google |
| `name` | VARCHAR(100) | Tên hiển thị |
| `avatar_url` | VARCHAR(500) | Avatar URL |
| `created_at` | TIMESTAMPTZ | Thời gian liên kết |

**Constraints:**
- `UNIQUE(provider, provider_user_id)` — 1 Google account chỉ link 1 user
- `UNIQUE(user_id, provider)` — 1 user chỉ link 1 Google account

### Bảng `Users` — Khác biệt khi dùng Google SSO

| Column | Đăng ký Email | Đăng ký Google SSO |
|--------|--------------|-------------------|
| `password_hash` | Hash mật khẩu | **NULL** |
| `email_verified` | `FALSE` → Chờ verify | **TRUE** |
| `email_verified_at` | NULL → verify | **DateTime.UtcNow** |
| `avatar_url` | NULL | Google Picture URL |

---

## PHẦN 5: LUỒNG HOÀN CHỈNH

```
=== WEB ===
1. User click "Đăng nhập bằng Google"
   → Google GIS popup hiện lên

2. User chọn tài khoản Google & đồng ý

3. Google trả về ID Token cho Frontend (JS callback)

4. Frontend gọi: POST /api/auth/google-login { idToken: "..." }

5. Backend verify ID Token → Find/Create User
   → Generate AccessToken + RefreshToken

6. Backend trả JSON response
   → Frontend lưu tokens vào localStorage

7. Frontend redirect đến trang chính ✓

=== MOBILE ===
1. User tap "Đăng nhập bằng Google"
   → Google Sign-In SDK hiện native dialog

2. User chọn tài khoản Google & đồng ý

3. SDK trả về ID Token cho app

4. App gọi: POST /api/auth/google-login { idToken: "..." }

5-7. Giống Web, nhưng lưu tokens vào SecureStore/Keychain ✓
```

---

## PHẦN 6: XỬ LÝ CÁC TRƯỜNG HỢP ĐẶC BIỆT

### User đăng ký Email trước → Sau đó đăng nhập Google (cùng email)

```
Trước: Users { email: "a@gmail.com", password_hash: "hash" }
Sau:   Users { email: "a@gmail.com", password_hash: "hash" }
       + UserAuthProviders { provider: "google", provider_user_id: "google-sub-123" }

→ User có thể đăng nhập bằng CẢ 2 cách (Email/Pass + Google SSO)
```

### User SSO-only muốn đặt mật khẩu

```
Gọi POST /api/auth/change-password
   - CurrentPassword: bỏ qua (vì password_hash = NULL)
   - NewPassword: mật khẩu mới
→ User có thể đăng nhập bằng cả 2 cách
```

### User có cả Google và Facebook

```
UserAuthProviders:
  { user_id: X, provider: "google",   provider_user_id: "google_sub_abc" }
  { user_id: X, provider: "facebook", provider_user_id: "fb_id_123" }

→ User đăng nhập bằng 3 cách: Email/Pass, Google SSO, Facebook SSO
```

---

## PHẦN 7: NUGET PACKAGE CẦN THIẾT

```xml
<PackageReference Include="Google.Apis.Auth" Version="1.68.0" />
```

Dùng `GoogleJsonWebSignature.ValidateAsync()` để verify ID Token — **không cần** AddGoogle() middleware.

---

## PHẦN 8: TROUBLESHOOTING

| Lỗi | Nguyên nhân | Cách sửa |
|-----|-------------|---------|
| `Invalid ID Token` | Token hết hạn hoặc sai audience | Kiểm tra `ClientId` trong `GoogleAuthSettings` |
| `Audience mismatch` | Client ID khác platform | Phải verify bằng **Web Client ID** |
| CORS error | FE và BE khác domain | Bật CORS + `AllowAnyOrigin` hoặc whitelist |
| Token null từ mobile | SDK config sai | Kiểm tra `SHA-1` (Android) hoặc `Bundle ID` (iOS) |

---

**Document Version**: 3.0 (Rewritten for AppPickleball token-based auth)
**Last Updated**: 2026-03-13
**Related Documents:**
- [Facebook_SSO_Login.md](./Facebook_SSO_Login.md) — Đăng nhập Facebook SSO
