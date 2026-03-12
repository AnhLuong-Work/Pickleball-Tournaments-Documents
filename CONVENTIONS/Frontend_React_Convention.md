# Frontend React Convention

**Stack:** React 18 + Vite + TypeScript + TailwindCSS
**State:** Zustand | **Data Fetching:** React Query (TanStack Query) | **HTTP:** Axios
**Router:** React Router v6 | **Forms:** React Hook Form + Zod | **Icons:** Lucide React

---

## 1. Folder Structure

```
src/
├── api/                    # Axios instance, API functions
│   ├── axios.ts            # Axios config + interceptors
│   ├── auth.api.ts
│   ├── tournament.api.ts
│   └── ...
│
├── components/
│   ├── ui/                 # Primitive UI (Button, Input, Modal, Badge...)
│   ├── layout/             # Header, Sidebar, BottomNav, PageLayout
│   └── common/             # Domain components (TournamentCard, ScoreDisplay...)
│
├── features/               # Feature-based modules
│   ├── auth/
│   │   ├── components/     # LoginForm, RegisterForm...
│   │   ├── hooks/          # useLogin, useRegister...
│   │   └── types.ts
│   ├── tournament/
│   ├── match/
│   ├── community/
│   ├── chat/
│   ├── profile/
│   └── notification/
│
├── hooks/                  # Global hooks (useDebounce, useInfiniteScroll...)
├── lib/                    # Utilities (formatDate, formatScore...)
├── routes/                 # Route definitions + guards
├── stores/                 # Zustand stores
│   ├── auth.store.ts
│   ├── notification.store.ts
│   └── signalr.store.ts
└── types/                  # Global TypeScript types/interfaces
```

---

## 2. Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Component | PascalCase | `TournamentCard.tsx` |
| Hook | camelCase với "use" | `useTournamentDetail.ts` |
| Store | camelCase với ".store" | `auth.store.ts` |
| API file | camelCase với ".api" | `tournament.api.ts` |
| Type/Interface | PascalCase | `Tournament`, `ApiResponse<T>` |
| Enum | PascalCase | `TournamentStatus` |
| Constants | UPPER_SNAKE_CASE | `MAX_GROUPS` |
| CSS class | kebab-case (Tailwind) | `text-sm font-medium` |

---

## 3. TypeScript Types

```typescript
// Global API response type
interface ApiResponse<T> {
  data: T;
  meta?: PaginationMeta;
}

interface PaginationMeta {
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
}

// Enum as const (prefer over TypeScript enum)
export const TournamentStatus = {
  DRAFT: 'draft',
  OPEN: 'open',
  READY: 'ready',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
} as const;
export type TournamentStatus = typeof TournamentStatus[keyof typeof TournamentStatus];
```

---

## 4. API Layer Pattern

```typescript
// api/tournament.api.ts
import { apiClient } from './axios';
import type { Tournament, CreateTournamentRequest, TournamentDto } from '@/types';

export const tournamentApi = {
  list: (params: TournamentListParams) =>
    apiClient.get<ApiResponse<Tournament[]>>('/tournaments', { params }),

  getById: (id: number) =>
    apiClient.get<ApiResponse<TournamentDto>>(`/tournaments/${id}`),

  create: (data: CreateTournamentRequest) =>
    apiClient.post<ApiResponse<TournamentDto>>('/tournaments', data),

  updateStatus: (id: number, status: TournamentStatus) =>
    apiClient.put(`/tournaments/${id}/status`, { status }),
};
```

---

## 5. React Query Pattern

```typescript
// features/tournament/hooks/useTournamentDetail.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { tournamentApi } from '@/api/tournament.api';

// Query Keys
export const tournamentKeys = {
  all: ['tournaments'] as const,
  lists: () => [...tournamentKeys.all, 'list'] as const,
  detail: (id: number) => [...tournamentKeys.all, 'detail', id] as const,
};

export function useTournamentDetail(id: number) {
  return useQuery({
    queryKey: tournamentKeys.detail(id),
    queryFn: () => tournamentApi.getById(id).then(r => r.data.data),
    staleTime: 1000 * 30, // 30s
  });
}

export function useUpdateTournamentStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: number; status: TournamentStatus }) =>
      tournamentApi.updateStatus(id, status),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: tournamentKeys.detail(id) });
    },
  });
}
```

---

## 6. Zustand Store Pattern

```typescript
// stores/auth.store.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  accessToken: string | null;
  refreshToken: string | null;
  user: UserProfile | null;
  isAuthenticated: boolean;
  setTokens: (access: string, refresh: string) => void;
  setUser: (user: UserProfile) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      refreshToken: null,
      user: null,
      isAuthenticated: false,
      setTokens: (accessToken, refreshToken) =>
        set({ accessToken, refreshToken, isAuthenticated: true }),
      setUser: (user) => set({ user }),
      logout: () => set({ accessToken: null, refreshToken: null, user: null, isAuthenticated: false }),
    }),
    { name: 'auth-storage' }
  )
);
```

---

## 7. Form Pattern (React Hook Form + Zod)

```typescript
const createTournamentSchema = z.object({
  name: z.string().min(3, 'Tên giải phải có ít nhất 3 ký tự').max(200),
  type: z.enum(['singles', 'doubles']),
  numGroups: z.number().min(1).max(4),
});

type CreateTournamentForm = z.infer<typeof createTournamentSchema>;

function CreateTournamentForm() {
  const { register, handleSubmit, formState: { errors } } =
    useForm<CreateTournamentForm>({ resolver: zodResolver(createTournamentSchema) });

  const mutation = useCreateTournament();

  const onSubmit = (data: CreateTournamentForm) => mutation.mutate(data);

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('name')} />
      {errors.name && <p className="text-red-500 text-sm">{errors.name.message}</p>}
    </form>
  );
}
```

---

## 8. Axios Interceptors

```typescript
// api/axios.ts
const apiClient = axios.create({ baseURL: import.meta.env.VITE_API_URL });

// Request: attach token
apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response: auto-refresh on 401
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true;
      // Refresh token logic
      const { refreshToken } = useAuthStore.getState();
      const { data } = await authApi.refresh(refreshToken!);
      useAuthStore.getState().setTokens(data.data.accessToken, data.data.refreshToken);
      error.config.headers.Authorization = `Bearer ${data.data.accessToken}`;
      return apiClient(error.config);
    }
    return Promise.reject(error);
  }
);
```

---

## 9. SignalR Hook Pattern

```typescript
// hooks/useSignalR.ts
import * as signalR from '@microsoft/signalr';

export function useTournamentHub(tournamentId: number) {
  const connectionRef = useRef<signalR.HubConnection | null>(null);

  useEffect(() => {
    const connection = new signalR.HubConnectionBuilder()
      .withUrl(`${import.meta.env.VITE_API_URL}/hubs/tournament`, {
        accessTokenFactory: () => useAuthStore.getState().accessToken ?? '',
      })
      .withAutomaticReconnect()
      .build();

    connection.start().then(() => {
      connection.invoke('JoinTournament', tournamentId);
    });

    connection.on('ScoreUpdated', (data) => { /* update query cache */ });
    connection.on('StandingsUpdated', (data) => { /* update query cache */ });

    connectionRef.current = connection;
    return () => { connection.stop(); };
  }, [tournamentId]);
}
```

---

## 10. Component Rules
- 1 file = 1 exported component (default export)
- Props interface trong cùng file hoặc types/ nếu shared
- Không dùng `any` — prefer `unknown` rồi type narrow
- Tránh prop drilling > 2 levels → dùng context hoặc Zustand
- Không gọi API trực tiếp trong component — luôn qua hooks
- Loading/Error states bắt buộc cho mọi async operation

---

## 11. TailwindCSS Rules
- Không dùng custom CSS nếu Tailwind đủ
- Breakpoints: `sm:` (640px) `md:` (768px) `lg:` (1024px) `xl:` (1280px)
- Dark mode: dùng class `dark:` nếu cần thiết
- Extract className thường dùng vào `cn()` helper (clsx + tailwind-merge)

```typescript
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
export const cn = (...inputs: ClassValue[]) => twMerge(clsx(inputs));
```
