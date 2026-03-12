# SignalR Contracts — Real-time Events

**Technology:** ASP.NET Core SignalR | **Transport:** WebSocket (fallback: Long Polling)
**Client packages:** `@microsoft/signalr` (Web/Mobile)

---

## Hub Overview

| Hub | Endpoint | Phase | Mô tả |
|-----|----------|:-----:|-------|
| TournamentHub | `/hubs/tournament` | 1 | Live scores, standings, match updates |
| NotificationHub | `/hubs/notification` | 1 | Real-time notifications, badge count |
| ChatHub | `/hubs/chat` | 2 | Tin nhắn, typing indicator, read receipts |

---

## Authentication

Tất cả hubs yêu cầu JWT token:
```javascript
// Client
const connection = new signalR.HubConnectionBuilder()
  .withUrl('/hubs/tournament', {
    accessTokenFactory: () => authStore.getAccessToken()
  })
  .withAutomaticReconnect([0, 2000, 10000, 30000]) // retry intervals (ms)
  .build();
```

---

## 1. TournamentHub — `/hubs/tournament`

### Mô Tả
Push live score và standings updates đến tất cả clients đang xem một giải đấu.

### Client → Server Methods

#### `JoinTournament(tournamentId: number)`
Đăng ký nhận updates của giải đấu.
```javascript
await connection.invoke('JoinTournament', 123);
```
Server: Thêm connection vào SignalR Group `"tournament_123"`.

#### `LeaveTournament(tournamentId: number)`
Hủy đăng ký.
```javascript
await connection.invoke('LeaveTournament', 123);
```

---

### Server → Client Events

#### `ScoreUpdated`
Fired khi Creator nhập/sửa điểm trận đấu.
```typescript
interface ScoreUpdatedPayload {
  matchId: number;
  tournamentId: number;
  groupId: number;
  round: number;
  player1Id: number;
  player2Id: number;
  player1Scores: number[];  // [11, 9, 11]
  player2Scores: number[];  // [7, 11, 8]
  winnerId: number | null;
  matchStatus: 'in_progress' | 'completed';
}

connection.on('ScoreUpdated', (data: ScoreUpdatedPayload) => {
  queryClient.setQueryData(['matches', data.matchId], (old) => ({ ...old, ...data }));
});
```

#### `StandingsUpdated`
Fired sau khi BXH được tính toán lại.
```typescript
interface StandingEntry {
  rank: number;
  playerId: number;
  playerName: string;
  avatarUrl: string | null;
  wins: number;
  losses: number;
  pointsFor: number;
  pointsAgainst: number;
  diff: number;
}

interface StandingsUpdatedPayload {
  tournamentId: number;
  groupId: number;
  groupName: string;
  standings: StandingEntry[];
}

connection.on('StandingsUpdated', (data: StandingsUpdatedPayload) => {
  queryClient.setQueryData(['standings', data.groupId], data.standings);
});
```

#### `MatchStatusChanged`
Fired khi trạng thái trận đấu thay đổi.
```typescript
interface MatchStatusChangedPayload {
  matchId: number;
  tournamentId: number;
  status: 'scheduled' | 'in_progress' | 'completed' | 'walkover';
}

connection.on('MatchStatusChanged', (data: MatchStatusChangedPayload) => { ... });
```

#### `TournamentStatusChanged`
Fired khi trạng thái giải đấu thay đổi.
```typescript
interface TournamentStatusChangedPayload {
  tournamentId: number;
  status: 'open' | 'ready' | 'in_progress' | 'completed' | 'cancelled';
}

connection.on('TournamentStatusChanged', (data: TournamentStatusChangedPayload) => { ... });
```

---

## 2. NotificationHub — `/hubs/notification`

### Mô Tả
Push notifications real-time đến user cụ thể. Client chỉ nhận events của chính mình.

### Connection
```javascript
const connection = new signalR.HubConnectionBuilder()
  .withUrl('/hubs/notification', {
    accessTokenFactory: () => authStore.getAccessToken()
  })
  .withAutomaticReconnect()
  .build();

await connection.start();
// Server tự add vào Group theo userId (không cần invoke method)
```

---

### Server → Client Events

#### `NewNotification`
Fired khi có notification mới cho user.
```typescript
interface NotificationPayload {
  id: number;
  type: string;  // 'tournament_invite' | 'request_approved' | ...
  title: string;
  body: string;
  data: {
    screen?: string;   // 'tournament' | 'chat' | 'profile' | 'game'
    id?: number;
  };
  isRead: false;
  createdAt: string;  // ISO 8601
}

connection.on('NewNotification', (notification: NotificationPayload) => {
  notificationStore.addNotification(notification);
});
```

#### `UnreadCountUpdated`
Fired sau khi `NewNotification` để update badge.
```typescript
interface UnreadCountPayload {
  count: number;
}

connection.on('UnreadCountUpdated', ({ count }: UnreadCountPayload) => {
  notificationStore.setUnreadCount(count);
});
```

---

## 3. ChatHub — `/hubs/chat` (Phase 2)

### Mô Tả
Real-time messaging, typing indicators, read receipts.

### Client → Server Methods

#### `SendMessage(roomId, content, type)`
```javascript
await connection.invoke('SendMessage', roomId, 'Chào mọi người!', 'text');
```

#### `TypingStart(roomId)` / `TypingStop(roomId)`
```javascript
// Debounce 500ms
await connection.invoke('TypingStart', roomId);
// 2s sau khi stop typing:
await connection.invoke('TypingStop', roomId);
```

#### `MarkAsRead(roomId, messageId)`
```javascript
await connection.invoke('MarkAsRead', roomId, lastMessageId);
```

#### `JoinRoom(roomId)` / `LeaveRoom(roomId)`
```javascript
await connection.invoke('JoinRoom', roomId);
```

---

### Server → Client Events

#### `MessageReceived`
```typescript
interface MessagePayload {
  id: number;
  roomId: number;
  senderId: number;
  senderName: string;
  senderAvatar: string | null;
  content: string;
  type: 'text' | 'image' | 'system';
  createdAt: string;
}

connection.on('MessageReceived', (message: MessagePayload) => {
  // Thêm vào message list nếu đang ở room đó
  // Cập nhật conversation list preview nếu không ở room đó
});
```

#### `UserTyping` / `UserStoppedTyping`
```typescript
interface TypingPayload {
  roomId: number;
  userId: number;
  userName: string;
}

connection.on('UserTyping', (data: TypingPayload) => {
  chatStore.setTyping(data.roomId, data.userId, data.userName);
});

connection.on('UserStoppedTyping', (data: TypingPayload) => {
  chatStore.removeTyping(data.roomId, data.userId);
});
```

#### `MessageRead`
```typescript
interface MessageReadPayload {
  roomId: number;
  userId: number;
  messageId: number;  // đã đọc đến message này
}

connection.on('MessageRead', (data: MessageReadPayload) => {
  // Cập nhật read receipt UI
});
```

---

## Client Implementation Pattern (React)

```typescript
// hooks/useSignalRConnection.ts
export function useSignalRConnection(hubUrl: string) {
  const connectionRef = useRef<signalR.HubConnection | null>(null);
  const { accessToken } = useAuthStore();

  useEffect(() => {
    if (!accessToken) return;

    const connection = new signalR.HubConnectionBuilder()
      .withUrl(hubUrl, { accessTokenFactory: () => accessToken })
      .withAutomaticReconnect([0, 2000, 10000, 30000])
      .configureLogging(signalR.LogLevel.Warning)
      .build();

    connection.onreconnecting(() => console.log('SignalR: reconnecting...'));
    connection.onreconnected(() => console.log('SignalR: reconnected'));
    connection.onclose(() => console.log('SignalR: connection closed'));

    connection.start().catch(console.error);
    connectionRef.current = connection;

    return () => { connection.stop(); };
  }, [hubUrl, accessToken]);

  return connectionRef;
}
```

---

## Error Handling

| Lỗi | Xử lý |
|-----|-------|
| Token hết hạn | `withAutomaticReconnect` + interceptor refresh token trước |
| Mất mạng | `withAutomaticReconnect` tự retry |
| Server restart | Client reconnect tự động, re-invoke `JoinTournament` sau reconnect |
| Group không tồn tại | Server trả error qua `HubException` |

---

## Performance Notes

- **Scale-out:** SignalR với Redis backplane cho multi-instance deployment
- **Group naming:** `tournament_{id}`, `user_{id}`, `chat_{roomId}`
- **Connection limit:** ~50K concurrent connections/instance (SignalR default)
- **Message size limit:** 32KB default (configurable)
