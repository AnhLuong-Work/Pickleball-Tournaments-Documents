# CLAUDE.md — pickleball-web (React Frontend)

> Copy file này vào root của repo `pickleball-web` với tên `CLAUDE.md`

---

## Project Overview

**pickleball-web** là React web app cho ứng dụng quản lý giải đấu Pickleball.
- **Stack:** React 18 · Vite · TypeScript · TailwindCSS · Zustand · React Query · Axios · SignalR
- **Router:** React Router v6
- **Forms:** React Hook Form + Zod
- **Backend:** kết nối với `AppPickleball` .NET 8 API

## Tài Liệu Tham Khảo
→ Đọc `Documents/CONVENTIONS/Frontend_React_Convention.md` trước khi code
→ Đọc `Documents/SCREEN-INVENTORY/Web_Screen_Inventory.md` cho danh sách screens
→ Đọc `Documents/API-CONTRACT/` cho API schema

## Build & Run

```bash
npm install
cp .env.example .env.local
# Set VITE_API_URL=https://localhost:7001/api

npm run dev    # http://localhost:5173
npm run build  # production build
npm run lint   # check errors
```

## Folder Structure

```
src/
├── api/          # Axios instance + API functions
├── components/
│   ├── ui/       # Primitive UI (Button, Input, Modal...)
│   ├── layout/   # Header, Sidebar, PageLayout
│   └── common/   # Domain components (TournamentCard...)
├── features/     # Feature modules (auth, tournament, match...)
├── hooks/        # Global hooks
├── lib/          # cn(), formatDate(), formatScore()
├── routes/       # AppRouter, ProtectedRoute
├── stores/       # Zustand stores
└── types/        # TypeScript types
```

## Rules — PHẢI tuân thủ

### API calls
- **Không gọi API trực tiếp trong component** — luôn qua custom hook
- Dùng **React Query** (`useQuery`, `useMutation`) cho tất cả server state
- `queryKeys` factory trong `src/lib/queryKeys.ts`

### Authentication
- `accessToken` lưu trong **Zustand store** (memory, không localStorage vì XSS)
- `refreshToken` lưu trong **httpOnly cookie** hoặc Zustand (nếu không dùng cookie)
- Axios interceptor tự động refresh khi 401 — không handle thủ công trong component

### Error Handling
- Tất cả API errors → dùng `sonner` toast để display
- Form validation errors → hiện inline dưới field
- Loading states → luôn có `<Spinner />` khi `isLoading`
- Empty states → luôn có `<EmptyState />` component

### TypeScript
- **Không dùng `any`** — dùng `unknown` rồi type-guard
- Tất cả API response phải type: `ApiResponse<T>`
- Enum values: dùng `as const` object, không `enum` keyword

### Components
- 1 file = 1 exported component (default export)
- Props interface trong cùng file hoặc `types/`
- Tránh prop drilling > 2 levels → dùng Zustand

### Styling
- **Chỉ dùng TailwindCSS** — không viết custom CSS
- Extract class phức tạp vào `cn()` helper
- Responsive: mobile-first (`md:`, `lg:`)

### Naming
- Component: `PascalCase` (TournamentCard.tsx)
- Hook: `useCamelCase` (useTournamentDetail.ts)
- Store: `camelCase.store.ts`
- API: `camelCase.api.ts`
- Constants: `UPPER_SNAKE_CASE`

## SignalR Connections
- TournamentHub: kết nối khi vào tournament detail page
- NotificationHub: kết nối khi đăng nhập, disconnect khi logout
- Tự động reconnect với `withAutomaticReconnect([0, 2000, 10000, 30000])`

## Build Verify
```bash
npm run build   # 0 TypeScript errors, 0 important warnings
npm run lint    # 0 ESLint errors
```

## Important Notes
- BE sử dụng `TIMESTAMPTZ` → tất cả dates là UTC, format khi hiển thị bằng `date-fns`
- API base URL: `VITE_API_URL` env variable — không hardcode
- Images upload qua `/users/me/avatar` → BE upload lên Cloudinary, trả về URL
