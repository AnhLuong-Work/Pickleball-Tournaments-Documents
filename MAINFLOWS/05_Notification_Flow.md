# Notification Flow — Luồng Thông Báo

**Module:** M7 — Notification | **Phase:** 1 (in-app) + Phase 2 (push)

---

## 1. Hai Loại Thông Báo

| Loại | Kênh | Khi nào |
|------|------|---------|
| **In-app** | DB + SignalR | Luôn, dù app đang mở hay không |
| **Push** | FCM (Firebase Cloud Messaging) | Khi user KHÔNG đang dùng app |

---

## 2. Flow Tạo In-App Notification

```
Sự kiện xảy ra (ví dụ: Creator duyệt participant)
    │
    ▼
Business Logic Handler (MediatR)
    │
    ▼
NotificationService.CreateAsync({
  userId: targetUserId,
  type: "request_approved",
  title: "Bạn đã được duyệt vào giải X",
  body: "Creator A đã duyệt yêu cầu tham gia của bạn",
  data: { tournamentId: 123 }
})
    │
    ▼
Lưu vào bảng Notifications (isRead = false)
    │
    ▼
[SignalR] Hub.Clients.User(targetUserId)
    .SendAsync("NewNotification", notificationDto)
    .SendAsync("UnreadCountUpdated", newCount)
    │
    ▼
Client nhận real-time update (nếu đang online)
```

---

## 3. Flow Push Notification (FCM)

```
User đăng nhập trên mobile
    │
    ▼
Client gửi FCM device token:
POST /auth/device-token { token: "fcm_token_here", platform: "android"|"ios" }
    │
    ▼
Lưu vào DeviceTokens table (userId → token)
    │
    ▼
[Khi có sự kiện cần push]
    │
    ▼
FCMService.SendAsync({
  token: deviceToken,
  title: "...",
  body: "...",
  data: { screen: "tournament", id: "123" }  ← deep link data
})
    │
    ▼
FCM API → thiết bị của user
    │
    ▼
User tap notification → app mở đúng màn hình (deep link)
```

---

## 4. Danh Sách Event → Notification Type

| Sự kiện | Type | Nhận thông báo |
|---------|------|----------------|
| Được mời vào giải đấu | `tournament_invite` | Player được mời |
| Đơn xin tham gia được duyệt | `request_approved` | Player xin vào |
| Đơn xin tham gia bị từ chối | `request_rejected` | Player xin vào |
| Lịch thi đấu được tạo | `match_scheduled` | Tất cả participants |
| Giải đấu bắt đầu | `tournament_started` | Tất cả participants |
| Kết quả trận đấu của mình | `match_result` | 2 player/team trong trận |
| Giải đấu kết thúc | `tournament_completed` | Tất cả participants |
| Giải đấu bị hủy | `tournament_cancelled` | Tất cả participants |
| Được mời vào game cộng đồng | `game_invite` | User được mời |
| Tin nhắn mới | `new_message` | Thành viên chat room |
| Có người theo dõi mới | `new_follower` | User được follow |
| Từ waitlist lên confirmed | `game_waitlist_promoted` | User trên waitlist |

---

## 5. Deep Link Schema (Mobile)

```
Notification data.screen → Navigate to:

"tournament"   + data.id  → TournamentDetailScreen
"match"        + data.id  → MatchDetailScreen
"chat"         + data.id  → ChatDetailScreen
"profile"      + data.id  → UserProfileScreen
"game"         + data.id  → CommunityGameDetailScreen
"notifications"           → NotificationListScreen
```

---

## 6. API Notification

```
GET /notifications
Query: page, pageSize, filter (all | unread | tournament | social)
    │
    ▼
Response: [
  {
    id, type, title, body, data,
    isRead, createdAt
  }
]
    │
    ▼
Client hiển thị danh sách

PUT /notifications/:id/read    ← đánh dấu 1 cái
PUT /notifications/read-all    ← đánh dấu tất cả
```

---

## 7. SignalR — Notification Hub

```
Hub endpoint: /hubs/notification

Client connect (sau khi login):
  connection.start()
  → Server auto-add vào Group theo userId

Server → Client events:
  "NewNotification"    { id, type, title, body, data, createdAt }
  "UnreadCountUpdated" { count: 5 }
```

**Lưu ý:** Client phải reconnect với accessToken mới khi token hết hạn.
