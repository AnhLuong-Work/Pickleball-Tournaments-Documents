# Hướng Dẫn Test Backend: Google & Facebook SSO

Tài liệu này hướng dẫn cách test các API Social Login của Backend mà không cần code Frontend hoàn chỉnh.

---

## 1. Test Google SSO (`POST /api/auth/google-login`)

Backend yêu cầu một **Google ID Token** hợp lệ để xác thực.

### Cách lấy ID Token thực tế để test:
1. Truy cập [Google OAuth 2.0 Playground](https://developers.google.com/oauthplayground/).
2. Click icon bánh răng ⚙️ (Settings):
   - Chọn **Use your own OAuth credentials**.
   - Nhập **OAuth Client ID** và **OAuth Client Secret** từ Google Cloud Console (Web Client).
   - Click **Close**.
3. **Step 1 (Select & authorize APIs):** 
   - Nhập: `openid email profile` vào ô text.
   - Click **Authorize APIs** → Đăng nhập tài khoản Google của bạn.
4. **Step 2 (Exchange authorization code for tokens):**
   - Click **Exchange authorization code for tokens**.
5. **Step 3 (Configure request to API):**
   - Bạn sẽ thấy ô **ID Token**. Copy chuỗi JWT dài này.

### Gọi API bằng Postman/Swagger:
- **Method:** `POST`
- **URL:** `https://localhost:5001/api/auth/google-login`
- **Body (JSON):**
```json
{
  "idToken": "CHUỖI_ID_TOKEN_VỪA_COPY"
}
```

---

## 2. Test Facebook SSO (`POST /api/auth/facebook-login`)

Backend yêu cầu một **Facebook Access Token** hợp lệ.

### Cách lấy Access Token thực tế để test:
1. Truy cập [Facebook Graph API Explorer](https://developers.facebook.com/tools/explorer/).
2. Ở bên phải, chọn **Facebook App** của bạn.
3. Phần **User or Page**, chọn **Get User Access Token**.
4. Chọn các quyền (Permissions): `email`, `public_profile`.
5. Click **Get Access Token** → Đăng nhập/Đồng ý.
6. Copy chuỗi **Access Token** hiện ra ở ô phía trên.

### Gọi API bằng Postman/Swagger:
- **Method:** `POST`
- **URL:** `https://localhost:5001/api/auth/facebook-login`
- **Body (JSON):**
```json
{
  "accessToken": "CHUỖI_ACCESS_TOKEN_VỪA_COPY"
}
```

---

## 3. Các kịch bản Test quan trọng (Test Cases)

| Kịch bản | Dữ liệu đầu vào | Kết quả mong đợi |
|----------|----------------|------------------|
| **Đăng nhập mới** | ID/Access Token của 1 tài khoản chưa từng đăng nhập | Backend tạo User mới, link Provider, trả về `isNewUser: true` + JWT |
| **Link tài khoản** | Token của email đã có trong DB (đăng ký bằng pass) | Backend link Provider vào user hiện có, trả về `isNewUser: false` + JWT |
| **Đăng nhập lại** | Token của tài khoản đã link trước đó | Trả về JWT nhanh chóng, không tạo mới record |
| **Token sai** | Chuỗi rác hoặc token hết hạn | Trả về `401 Unauthorized` |
| **Facebook không email** | Token Facebook (bỏ quyền email) | Backend tạo user với email placeholder `fb_...`, `emailVerified: false` |

---

## 4. Kiểm tra Database sau khi test

Sau khi gọi API thành công, hãy kiểm tra SQL:

### Kiểm tra liên kết provider:
```sql
SELECT * FROM "UserAuthProviders" WHERE "Provider" = 'google' OR "Provider" = 'facebook';
```
- Phải có record ứng với `UserId`.

### Kiểm tra User:
```sql
SELECT "Id", "Email", "Name", "PasswordHash", "EmailVerified" FROM "Users" WHERE "Email" = 'email_vừa_test@gmail.com';
```
- `PasswordHash` phải là `NULL` nếu là user mới tạo từ SSO.
- `EmailVerified` phải là `TRUE` (với Google).

---

## 5. Lưu ý cho Developer

- **Token hết hạn:** ID Token và Access Token có thời gian sống ngắn. Nếu test bị lỗi 401, hãy lấy token mới từ Playground/Explorer.
- **HTTPS:** Backend ASP.NET Core yêu cầu HTTPS cho login. Hãy đảm bảo bạn đã chạy `dotnet dev-certs https --trust`.
- **CORS:** Nếu test từ 1 domain khác bằng fetch/axios, hãy đảm bảo Backend đã cho phép domain đó.

---

**Document Version**: 1.0
**Last Updated**: 2026-03-13
