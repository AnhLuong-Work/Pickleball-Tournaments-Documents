# MAINFLOWS — Tổng Quan Luồng Nghiệp Vụ

**Phiên bản:** 1.0 | **Ngày:** Tháng 3, 2026

---

## Danh Sách Luồng

| File | Luồng | Phase | Mô tả ngắn |
|------|-------|:-----:|------------|
| [01_Auth_Flow.md](./01_Auth_Flow.md) | Authentication | 1 | Đăng ký, đăng nhập, OAuth2, refresh token, đổi mật khẩu |
| [02_Tournament_Lifecycle_Flow.md](./02_Tournament_Lifecycle_Flow.md) | Tournament Lifecycle | 1 | Vòng đời giải đấu từ draft → completed |
| [03_Match_Scoring_Flow.md](./03_Match_Scoring_Flow.md) | Match & Scoring | 1 | Tạo lịch đấu, nhập điểm, cập nhật BXH real-time |
| [04_Community_Game_Flow.md](./04_Community_Game_Flow.md) | Community Game | 2 | Tạo game giao hữu, tham gia, waitlist |
| [05_Notification_Flow.md](./05_Notification_Flow.md) | Notification | 1 | In-app notification và push notification (FCM) |

---

## Sơ Đồ Quan Hệ Giữa Các Luồng

```
[Auth Flow]
    │
    ▼
User đăng nhập → có JWT
    │
    ├──► [Tournament Lifecycle Flow]
    │         │
    │         ▼
    │    Creator tạo giải → open → xếp bảng
    │         │
    │         ▼
    │    [Match Scoring Flow]
    │         │
    │         ▼
    │    Nhập điểm → BXH real-time (SignalR) → completed
    │
    ├──► [Community Game Flow] (Phase 2)
    │         │
    │         ▼
    │    Tạo game → join → in_progress
    │
    └──► [Notification Flow]
              ▲ (các luồng trên trigger notifications)
```

---

## Trạng Thái Quan Trọng

### Tournament Status
```
draft → open → ready → in_progress → completed
                                    ↘
                              cancelled (bất kỳ lúc nào trước completed)
```

### Participant Status
```
invited_pending → confirmed
request_pending → confirmed | rejected
```

### Match Status
```
scheduled → in_progress → completed
                        → walkover
```

### Community Game Status
```
open → full → in_progress → completed
    ↘ cancelled
```

---

## Actors & Permissions Quick Reference

| Action | Actor |
|--------|-------|
| Tạo giải, mời người, xếp bảng, nhập điểm | Creator |
| Xin tham gia, rời giải, xem lịch đấu | Player/User |
| Tạo game cộng đồng, mời người | GameCreator (bất kỳ User) |
| Xem thông tin công khai | Guest |
| Quản lý toàn hệ thống | Admin |
