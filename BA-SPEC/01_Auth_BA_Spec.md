# BA Spec — Auth & Profile

**Module:** M1 | **Phase:** 1

---

## F1. Đăng Ký

### Acceptance Criteria
- [ ] User nhập email, password, name → tạo tài khoản thành công
- [ ] Sau đăng ký → nhận email OTP, chuyển sang màn verify
- [ ] Không thể đăng nhập khi email chưa verify
- [ ] Email đã tồn tại → trả lỗi 409 với message rõ ràng
- [ ] OTP hết hạn sau 15 phút → user có thể gửi lại

### Validation Rules
| Field | Rule |
|-------|------|
| `email` | Required, valid email format, unique (case-insensitive) |
| `password` | Min 8 chars, ít nhất 1 chữ hoa, 1 số, 1 ký tự đặc biệt |
| `name` | Required, 2–100 ký tự, không chỉ có khoảng trắng |

### Edge Cases
- Email "TEST@gmail.com" và "test@gmail.com" coi là cùng 1 email
- OTP gửi lại: rate limit 1 lần/60 giây
- Sau 3 lần gửi OTP → yêu cầu đăng ký lại

---

## F2. Đăng Nhập

### Acceptance Criteria
- [ ] Email + password đúng → nhận accessToken + refreshToken
- [ ] Email/password sai → 401 (cùng message, không phân biệt để chống enumeration)
- [ ] Sau 5 lần sai trong 15 phút → khóa 15 phút, trả 429
- [ ] Email chưa verify → 403 + link gửi lại OTP
- [ ] Login thành công → xóa failed attempt count

### Business Rules
- accessToken TTL: 15 phút
- refreshToken TTL: 7 ngày
- Mỗi thiết bị có refreshToken riêng (multi-device support)
- Login trên thiết bị mới KHÔNG làm mất session thiết bị cũ

---

## F3. OAuth2

### Acceptance Criteria
- [ ] Google login trên web: Google OAuth popup
- [ ] Google login trên mobile: Google Sign-In SDK
- [ ] Apple Sign In: chỉ hiển thị trên iOS
- [ ] Lần đầu OAuth → tạo User mới (isEmailVerified = true tự động)
- [ ] Email OAuth đã tồn tại dưới dạng email/password → link account (tạo thêm UserAuthProvider)

### Edge Cases
- User đăng ký bằng Google, sau đó muốn đặt password → có flow "Set Password"
- Apple ẩn email thật → lưu apple_private_relay_email, hỏi user đặt email thật khi cần

---

## F4. Refresh Token

### Business Rules
- Implement **Refresh Token Rotation**: mỗi lần refresh → tạo token mới, xóa token cũ
- Nếu refreshToken cũ bị dùng (token reuse detection) → **revoke toàn bộ session** của user đó (tất cả thiết bị)
- refreshToken chỉ dùng 1 lần

---

## F5. Đổi Mật Khẩu

### Acceptance Criteria
- [ ] Phải nhập currentPassword đúng
- [ ] newPassword phải khác currentPassword
- [ ] Sau đổi thành công → revoke TẤT CẢ refreshTokens (force re-login mọi thiết bị)
- [ ] User nhận email thông báo "Mật khẩu đã được thay đổi"

---

## F6. Quản Lý Hồ Sơ

### Acceptance Criteria
- [ ] User có thể update: name, bio, skillLevel, dominantHand, paddleType
- [ ] Upload avatar: chỉ chấp nhận JPEG/PNG/WEBP, max 5MB
- [ ] Avatar được resize về 256×256 trước khi upload Cloudinary
- [ ] SkillLevel: 1.0–5.0, bước 0.5

### Privacy Rules
- Các thông tin công khai: name, avatarUrl, bio, skillLevel, matchHistory
- Thông tin riêng tư (chỉ bản thân xem): email, dominantHand (tùy setting)

---

## F7. Follow System

### Acceptance Criteria
- [ ] Follow → tạo Follows record, không cần xác nhận (không phải "friend request")
- [ ] Bỏ follow → xóa Follows record
- [ ] Follow chính mình → 422 "Không thể tự theo dõi mình"
- [ ] Follow 2 chiều → hiển thị badge "Theo dõi nhau" (mutual follow)
- [ ] Optimistic UI: UI update ngay, rollback nếu API fail

### Business Rules
- Không giới hạn số người follow/follower
- Không có notification khi bỏ follow

---

## F8. Xem Hồ Sơ Người Khác

### Acceptance Criteria
- [ ] Hiển thị: avatar, name, bio, skillLevel, stats (số giải, W/L)
- [ ] Hiển thị lịch sử trận đấu (chỉ completed matches)
- [ ] Không hiển thị email
- [ ] Nếu cả 2 đã từng đấu nhau → hiển thị H2H stats (thắng X, thua Y)
