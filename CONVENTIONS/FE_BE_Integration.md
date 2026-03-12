# FE-BE Integration — Auth Flow, Error Handling, Token Storage

---

## 1. Token Storage Strategy

### Quyết định: Memory Store (Zustand) + Refresh Cookie

```
accessToken  → Zustand store (RAM) — mất khi refresh tab ✓ bảo mật XSS
refreshToken → Zustand store (RAM) + localStorage (persist session)

NOTE: httpOnly cookie cho refreshToken là tốt nhất về security,
nhưng yêu cầu BE set cookie. Với app này: lưu localStorage + xóa khi logout.
```

### Implementation
```typescript
// stores/auth.store.ts
export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      accessToken: null,      // RAM only (không persist)
      refreshToken: null,     // Persist localStorage
      user: null,
      isAuthenticated: false,

      setTokens: (access, refresh) => set({
        accessToken: access,
        refreshToken: refresh,
        isAuthenticated: true,
      }),
      logout: () => {
        set({ accessToken: null, refreshToken: null, user: null, isAuthenticated: false });
        // Clear all query cache
        queryClient.clear();
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        refreshToken: state.refreshToken,  // chỉ persist refreshToken
        user: state.user,
      }),
    }
  )
);
```

---

## 2. Axios Interceptors — Complete Implementation

```typescript
// api/axios.ts
import axios from 'axios';

let isRefreshing = false;
let failedQueue: Array<{ resolve: Function; reject: Function }> = [];

const processQueue = (error: Error | null, token: string | null) => {
  failedQueue.forEach(({ resolve, reject }) => {
    if (error) reject(error);
    else resolve(token);
  });
  failedQueue = [];
};

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  timeout: 30000,
});

// Request interceptor — attach token
apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor — auto-refresh on 401
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // Nếu đang refresh, queue request này lại
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then((token) => {
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return apiClient(originalRequest);
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      const refreshToken = useAuthStore.getState().refreshToken;

      if (!refreshToken) {
        useAuthStore.getState().logout();
        window.location.href = '/auth/login';
        return Promise.reject(error);
      }

      try {
        const { data } = await axios.post(
          `${import.meta.env.VITE_API_URL}/auth/refresh`,
          { refreshToken }
        );
        const { accessToken, refreshToken: newRefreshToken } = data.data;
        useAuthStore.getState().setTokens(accessToken, newRefreshToken);

        processQueue(null, accessToken);
        originalRequest.headers.Authorization = `Bearer ${accessToken}`;
        return apiClient(originalRequest);

      } catch (refreshError) {
        processQueue(refreshError as Error, null);
        useAuthStore.getState().logout();
        window.location.href = '/auth/login';
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);
```

---

## 3. Error Handling — Display Strategy

### API Error Response Format (từ BE)
```json
{
  "message": "Mật khẩu hiện tại không đúng",
  "statusCode": 400,
  "errorCode": "VALIDATION_ERROR",
  "errors": {
    "currentPassword": ["Mật khẩu không đúng"]
  }
}
```

### FE Error Handler
```typescript
// lib/handleApiError.ts
import { toast } from 'sonner';
import { AxiosError } from 'axios';

export function handleApiError(error: unknown, fallbackMessage = 'Đã có lỗi xảy ra') {
  if (error instanceof AxiosError) {
    const apiError = error.response?.data;

    // Validation errors (400)
    if (error.response?.status === 400 && apiError?.errors) {
      // Trả về errors object cho React Hook Form
      return apiError.errors;
    }

    // Business rule errors (422)
    if (error.response?.status === 422) {
      toast.error(apiError?.message || 'Thao tác không hợp lệ');
      return null;
    }

    // Not found (404)
    if (error.response?.status === 404) {
      toast.error(apiError?.message || 'Không tìm thấy dữ liệu');
      return null;
    }

    // Rate limit (429)
    if (error.response?.status === 429) {
      toast.error('Quá nhiều yêu cầu. Vui lòng thử lại sau.');
      return null;
    }

    // Server error (500)
    if (error.response?.status >= 500) {
      toast.error('Lỗi hệ thống. Vui lòng thử lại sau.');
      return null;
    }

    toast.error(apiError?.message || fallbackMessage);
    return null;
  }

  // Network error
  if (!navigator.onLine) {
    toast.error('Không có kết nối mạng');
    return null;
  }

  toast.error(fallbackMessage);
  return null;
}
```

### Dùng trong Mutation
```typescript
const mutation = useMutation({
  mutationFn: (data) => tournamentApi.create(data),
  onSuccess: () => {
    toast.success('Tạo giải đấu thành công!');
    navigate('/tournaments');
  },
  onError: (error) => {
    handleApiError(error, 'Không thể tạo giải đấu');
  }
});
```

### Form với Server Validation
```typescript
const { setError } = useForm();

const mutation = useMutation({
  onError: (error) => {
    const fieldErrors = handleApiError(error);
    if (fieldErrors) {
      // Map server errors vào form fields
      Object.entries(fieldErrors).forEach(([field, messages]) => {
        setError(field as any, { message: (messages as string[])[0] });
      });
    }
  }
});
```

---

## 4. CORS Configuration (BE)

**`Program.cs` hoặc `CorsExtensions.cs`:**
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy
            .WithOrigins(
                "http://localhost:5173",          // Vite dev
                "http://localhost:3000",          // Alternative dev
                "https://pickleballapp.com",      // Production web
                "https://www.pickleballapp.com"   // Production www
            )
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();  // Cần cho SignalR
    });
});

// Trong pipeline:
app.UseCors("AllowFrontend");  // TRƯỚC Authentication
```

---

## 5. Protected Routes

```typescript
// routes/ProtectedRoute.tsx
export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { isAuthenticated, refreshToken } = useAuthStore();

  // Có refreshToken nhưng chưa có accessToken (sau page refresh)
  // → thử refresh trước khi redirect
  const { isLoading } = useQuery({
    queryKey: ['auth', 'refresh'],
    queryFn: async () => {
      if (!isAuthenticated && refreshToken) {
        const { data } = await authApi.refresh(refreshToken);
        useAuthStore.getState().setTokens(data.data.accessToken, data.data.refreshToken);
        return true;
      }
      return isAuthenticated;
    },
    enabled: !isAuthenticated && !!refreshToken,
    retry: false,
  });

  if (isLoading) return <FullPageSpinner />;
  if (!isAuthenticated && !refreshToken) return <Navigate to="/auth/login" replace />;

  return <>{children}</>;
}
```

---

## 6. Loading & Empty States — Rules

```typescript
// Luôn handle 3 states: loading, error, empty

function TournamentListPage() {
  const { data, isLoading, error } = useTournaments();

  if (isLoading) return <TournamentListSkeleton />;  // Skeleton, không Spinner

  if (error) return (
    <ErrorState
      message="Không thể tải danh sách giải đấu"
      onRetry={() => refetch()}
    />
  );

  if (!data?.length) return (
    <EmptyState
      title="Chưa có giải đấu nào"
      description="Tạo giải đấu đầu tiên của bạn"
      action={<Button onClick={() => navigate('/tournaments/create')}>Tạo giải đấu</Button>}
    />
  );

  return <TournamentList items={data} />;
}
```

---

## 7. Optimistic Updates (Follow/Unfollow)

```typescript
const followMutation = useMutation({
  mutationFn: (userId: number) => userApi.follow(userId),
  onMutate: async (userId) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries({ queryKey: userKeys.profile(userId) });

    // Snapshot current value
    const previousProfile = queryClient.getQueryData(userKeys.profile(userId));

    // Optimistically update
    queryClient.setQueryData(userKeys.profile(userId), (old: UserProfile) => ({
      ...old,
      isFollowing: true,
      followersCount: old.followersCount + 1,
    }));

    return { previousProfile };
  },
  onError: (_, userId, context) => {
    // Rollback on error
    queryClient.setQueryData(userKeys.profile(userId), context?.previousProfile);
    toast.error('Không thể theo dõi người dùng này');
  },
  onSettled: (_, __, userId) => {
    queryClient.invalidateQueries({ queryKey: userKeys.profile(userId) });
  },
});
```
