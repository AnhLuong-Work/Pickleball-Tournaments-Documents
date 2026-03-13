# Agent Skills & Team Guide

---

## Claude Code Skills Có Sẵn

### Backend Skills

| Skill | Gọi bằng | Mô tả |
|-------|---------|-------|
| `/create-feature` | `/create-feature` | Tạo feature mới theo CQRS pattern: Command/Query + Handler + Validator + Controller + Repository Interface + DI wiring |
| `/create-entity` | `/create-entity` | Tạo Entity mới với EF Core Configuration + DbSet (KHÔNG tạo repository) |
| `/create-api-endpoint` | `/create-api-endpoint` | Thêm endpoint mới vào Controller đã có |
| `/create-dto` | `/create-dto` | Tạo DTO với manual mapping từ Entity |
| `/add-resource-keys` | `/add-resource-keys` | Thêm keys song ngữ VI/EN vào 3 file .resx |
| `/build-api` | `/build-api` | Tạo/cập nhật API endpoint đầy đủ trong .NET Clean Architecture |
| `/api-test` | `/api-test` | Chạy live HTTP tests chống lại API đang chạy |
| `/api-fix` | `/api-fix` | Tự động fix API errors dựa trên kết quả test |
| `/api-doc` | `/api-doc` | Tạo API documentation |
| `/debug-runtime` | `/debug-runtime` | Debug runtime errors phổ biến |

### Document Skills

| Skill | Gọi bằng | Mô tả |
|-------|---------|-------|
| `/create-api-contract` | `/create-api-contract` | Tạo API contract document cho 1 module |
| `/split-api-contract` | `/split-api-contract` | Chia 1 file API tổng hợp thành nhiều file module |

---

## Agent Team Có Sẵn (BE Project)

| Agent | Model | Vai trò | Cách gọi |
|-------|-------|---------|---------|
| `backend-dev` | Sonnet | Implement features, CQRS handlers, fix bugs | "Use backend-dev to implement feature X" |
| `architect` | Opus | System design, architecture review, refactoring plan | "Use architect to review module Y" |
| `tester` | Haiku | Viết xUnit tests, check coverage | "Use tester to write tests for Z" |

---

## Workflow Thêm Feature Mới (Backend)

### Bước 1: Đọc spec
Đọc `BA-SPEC/` file tương ứng trước khi code.

### Bước 2: Chạy skill
```bash
/create-feature TournamentFeature
```
Skill sẽ hỏi:
- Domain name (vd: `Tournament`)
- Feature name (vd: `CreateTournament`)
- Command hay Query?
- Fields cần thiết

### Bước 3: Kiểm tra
```bash
dotnet build
```
Luôn verify sau khi code xong.

### Bước 4: Test API
```bash
/api-test
```
Kiểm tra endpoint hoạt động đúng.

---

## Git Workflow (Agent Rules)

> **QUAN TRỌNG:** Agent KHÔNG được commit trực tiếp vào `main`, `master`, `develop`, `develop-*`

```bash
# 1. Tạo branch mới
git checkout -b agent/YYYYMMDD-short-slug

# 2. Commit
git add <specific files>
git commit -m "feat: Add CreateTournament command"

# 3. Tạo PR (KHÔNG push thẳng, KHÔNG merge)
# Dùng GitHub REST API
TOKEN=$(printf "protocol=https\nhost=github.com\n" | git credential fill 2>/dev/null | grep "^password=" | cut -d= -f2)
curl -s -X POST -H "Authorization: token $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"feat: Add CreateTournament","body":"...","head":"agent/branch","base":"develop"}' \
  https://api.github.com/repos/OWNER/REPO/pulls
```

---

## Khi Nào Dùng Agent Nào

| Tình huống | Dùng |
|-----------|------|
| Implement 1 feature cụ thể | `backend-dev` agent |
| Cần review kiến trúc trước khi code | `architect` agent |
| Viết unit/integration tests | `tester` agent |
| Implement nhanh + test luôn | `backend-dev` → `/api-test` |
| Thiết kế DB schema mới | `architect` → `CREATE-ENTITY` skill |
| Debug production issue | `/debug-runtime` skill |

---

## Checklist Trước Khi Submit PR

- [ ] `dotnet build` thành công, 0 errors
- [ ] Tất cả endpoints mới có `[SwaggerOperation]` + `[ProducesResponseType]`
- [ ] Validation rules khớp với BA-SPEC
- [ ] Strings đều trong `.resx` files (không hardcode)
- [ ] `DateTime.UtcNow` (không `DateTime.Now`)
- [ ] Manual mapping (không AutoMapper)
- [ ] Không gọi `SaveChanges` trực tiếp trong repository
- [ ] API contract document cập nhật (nếu có endpoint mới)
