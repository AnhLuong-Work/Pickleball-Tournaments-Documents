# BA Spec — Notification

**Module:** M7 | **Phase:** 1 (in-app) + Phase 2 (push)

---

## F1. In-App Notification

### Acceptance Criteria
- [ ] Mọi sự kiện trong hệ thống → tạo Notification record trong DB
- [ ] User online → nhận real-time qua SignalR
- [ ] User offline → xem khi mở app (query DB)
- [ ] Badge count trên notification icon = số isRead=false
- [ ] Mark as read: cập nhật isRead=true
- [ ] Mark all read: cập nhật tất cả isRead=false → true

### Notification Data Structure
```json
{
  "id": 1,
  "type": "tournament_invite",
  "title": "Bạn được mời vào giải ABC",
  "body": "Creator Nguyễn Văn A mời bạn tham gia giải đấu hôm nay lúc 8h",
  "data": {
    "tournamentId": 123,
    "screen": "tournament"
  },
  "isRead": false,
  "createdAt": "2026-03-12T10:00:00Z"
}
```

### Business Rules
- Notification không xóa được (chỉ mark read)
- Giữ notification tối đa 90 ngày (cron job xóa cũ)
- Tối đa 100 notifications/user (xóa cũ hơn khi vượt)

---

## F2. Push Notification (FCM)

### Acceptance Criteria
- [ ] User đăng nhập mobile → app gửi FCM token lên server
- [ ] 1 user có thể có nhiều device token (nhiều thiết bị)
- [ ] Token hết hạn (FCM unregister) → tự động xóa khỏi DB
- [ ] Chỉ push khi user KHÔNG có SignalR connection active (offline hoặc app background)

### FCM Payload
```json
{
  "notification": {
    "title": "Bạn được mời vào giải ABC",
    "body": "Creator A mời bạn..."
  },
  "data": {
    "screen": "tournament",
    "id": "123",
    "type": "tournament_invite"
  },
  "android": {
    "priority": "high",
    "notification": { "channel_id": "tournament_channel" }
  },
  "apns": {
    "payload": {
      "aps": { "badge": 1, "sound": "default" }
    }
  }
}
```

### Push Priority by Type
| Type | Priority | Sound |
|------|:--------:|:-----:|
| `tournament_invite` | High | ✅ |
| `request_approved` | High | ✅ |
| `match_result` | Normal | ✅ |
| `new_message` | High | ✅ |
| `new_follower` | Low | ❌ |
| `tournament_cancelled` | High | ✅ |

---

## F3. Notification Settings (Future)

### Business Rules (Phase 2+)
- User có thể tắt notification theo type
- User có thể tắt "Do Not Disturb" theo giờ
- Settings lưu trong UserNotificationSettings table

---

## F4. Notification Badge (Mobile)

### Acceptance Criteria
- [ ] Badge trên app icon = tổng unread notifications
- [ ] Badge cập nhật real-time khi có notification mới
- [ ] Khi mark all read → badge về 0
- [ ] iOS: cần Expo Notifications permission
- [ ] Android: badge tự động từ notification channel
