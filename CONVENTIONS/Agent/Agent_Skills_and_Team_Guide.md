# Agent Skills & Agent Team — Hướng dẫn toàn diện

> Tài liệu hướng dẫn cách sử dụng Agent Skills (Workflows) và Multi-Agent trong thực tế,
> áp dụng cho project AppPickleball.

---

## Mục lục

1. [Agent Skills là gì?](#1-agent-skills-là-gì)
2. [Cấu trúc và cách tạo Skills](#2-cấu-trúc-và-cách-tạo-skills)
3. [Agent Team (Multi-Agent) là gì?](#3-agent-team-multi-agent-là-gì)
4. [Các mô hình Multi-Agent](#4-các-mô-hình-multi-agent)
5. [Setup Complexity & Communication Overhead](#5-setup-complexity--communication-overhead)
6. [So sánh Single Agent vs Multi-Agent](#6-so-sánh-single-agent-vs-multi-agent)
7. [Áp dụng thực tế cho AppPickleball](#7-áp-dụng-thực-tế-cho-AppPickleball)

---

## 1. Agent Skills là gì?

**Agent Skills** = bộ hướng dẫn tùy chỉnh mà bạn viết sẵn để agent tuân theo khi thực hiện tác vụ cụ thể.

### Tại sao cần Skills?

Không có Skills:
```
Bạn: "Thêm API forgot-password"
Agent: Tự nghĩ cách làm → có thể quên thêm resource keys,
       đặt sai folder, dùng sai pattern...
```

Có Skills:
```
Bạn: "/create-feature"
Agent: Đọc workflow → làm đúng 7 bước → không bỏ sót bước nào
```

### Skills hoạt động ở đâu?

| Platform | File config | Skills/Workflows | Auto-read |
|---|---|---|---|
| **Claude Code** | `CLAUDE.md` | `.agent/workflows/*.md` | ✅ |
| **Gemini CLI** | `CLAUDE.md` hoặc `GEMINI.md` | `.agent/workflows/*.md` | ✅ |
| **Cursor** | `.cursorrules` | Không có workflows | ✅ |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Không có workflows | ✅ |

> **Quan trọng:** `CLAUDE.md` và `.agent/workflows/` hoạt động trên **cả Claude Code lẫn Gemini CLI** — cùng format!

---

## 2. Cấu trúc và cách tạo Skills

### 2.1 File CLAUDE.md (Project-level instructions)

Đây là "bộ não" agent đọc đầu tiên mỗi session:

```
AppPickleball/
├── CLAUDE.md              ← Agent đọc TỰ ĐỘNG khi bắt đầu
```

**Nội dung nên có:**
- Project overview & architecture
- Build & run commands
- Key patterns (CQRS, Repository, UoW...)
- Code conventions
- Domain model summary

### 2.2 Workflows (Task-specific instructions)

```
AppPickleball/
├── .agent/
│   └── workflows/
│       ├── create-feature.md    ← /create-feature
│       ├── create-entity.md     ← /create-entity
│       ├── add-resource-keys.md ← /add-resource-keys
│       ├── fix-ef-warnings.md   ← /fix-ef-warnings
│       └── debug-runtime.md     ← /debug-runtime
```

### Format workflow file

```markdown
---
description: Mô tả ngắn (hiển thị khi user gõ /help)
---

# Tên Workflow

## Các bước thực hiện

// turbo-all    ← Agent tự chạy commands, không hỏi confirm

### 1. Bước 1
Mô tả chi tiết...

### 2. Bước 2
Mô tả chi tiết...
```

### 2.3 Annotations đặc biệt

| Annotation | Ý nghĩa |
|---|---|
| `// turbo` | Tự chạy **1 bước** ngay sau annotation |
| `// turbo-all` | Tự chạy **TẤT CẢ** các bước trong workflow |
| Không annotation | Agent hỏi confirm trước mỗi command |

### 2.4 Advanced Skills (nâng cao)

Skills phức tạp có thể có thêm scripts và examples:

```
.agent/
└── skills/
    └── database-migration/
        ├── SKILL.md           ← Hướng dẫn chính
        ├── scripts/
        │   └── validate-migration.ps1
        ├── examples/
        │   └── sample-migration.cs
        └── resources/
            └── column-naming-rules.md
```

---

## 3. Agent Team (Multi-Agent) là gì?

**Multi-Agent** = nhiều AI agent phối hợp, mỗi agent chuyên 1 vai trò.

### Single Agent (1 người làm tất cả)

```
┌──────────────────────────────────┐
│          Single Agent            │
│                                  │
│  Plan → Code → Test → Review    │
│  (1 context, 1 conversation)    │
└──────────────────────────────────┘
```

### Multi Agent (team phân công)

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ Planner  │──▶│  Coder   │──▶│ Reviewer │──▶│  Tester  │
│          │   │          │   │          │   │          │
│ Chuyên   │   │ Chuyên   │   │ Chuyên   │   │ Chuyên   │
│ phân tích│   │ viết code│   │ review   │   │ test     │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
  Context A      Context B      Context C      Context D
```

---

## 4. Các mô hình Multi-Agent

### 4.1 Sequential (Tuần tự — Dây chuyền)

```
Input → Agent A → Agent B → Agent C → Output
```

**Ví dụ thực tế:**
```
User yêu cầu "Thêm Forgot Password"

Agent A (Planner):
  → Đọc CLAUDE.md, SQL schema
  → Output: implementation_plan.md

Agent B (Coder):
  → Nhận plan → viết code
  → Output: 8 source files

Agent C (Reviewer):
  → Đọc code → check conventions
  → Output: "Thiếu resource key TokenExpired trong .vi.resx"

Agent B (Coder - lần 2):
  → Fix theo review
  → Output: files đã sửa

Agent D (Tester):
  → dotnet build → dotnet test
  → Output: "Build succeeded. 0 errors."
```

**Ưu:** Mỗi agent focus 1 việc → chất lượng cao.
**Nhược:** Chậm — phải chờ từng agent xong mới chuyển tiếp.

### 4.2 Hierarchical (Phân cấp — Có sếp)

```
         ┌───────────┐
         │  Manager  │  ← Phân task, orchestrate
         └─────┬─────┘
         ┌─────┼─────┐
         ▼     ▼     ▼
      ┌────┐ ┌────┐ ┌────┐
      │ A  │ │ B  │ │ C  │  ← Làm song song
      └────┘ └────┘ └────┘
```

**Ví dụ:**
```
Manager Agent:
  "Tạo 3 features: Forgot Password, Reset Password, Change Password"
  → Giao Agent A: Forgot Password
  → Giao Agent B: Reset Password
  → Giao Agent C: Change Password
  → Thu kết quả → merge → verify
```

**Ưu:** Song song → nhanh hơn.
**Nhược:** Manager agent cần hiểu rõ toàn bộ để phân task đúng.

### 4.3 Collaborative (Thảo luận — Peer review)

```
  Coder  ←→  Reviewer
    ↑            ↓
    └───── Fix ──┘
```

**Ví dụ:**
```
Round 1:
  Coder: "Đây là code cho ForgotPasswordHandler.cs"
  Reviewer: "IRepository.Update() là void, không await được. Sửa lại."

Round 2:
  Coder: "Đã sửa, bỏ await Update()"
  Reviewer: "LGTM ✅"
```

**Ưu:** Bắt lỗi tốt nhờ phản biện.
**Nhược:** Nhiều round → tốn token, tốn thời gian.

---

## 5. Setup Complexity & Communication Overhead

### 5.1 Setup Complexity (Phức tạp khi cài đặt)

#### ❌ Những gì phải setup cho Multi-Agent:

**a) Định nghĩa Agent Roles:**
```python
# Ví dụ CrewAI — phải define từng agent
planner = Agent(
    role="Senior Architect",
    goal="Phân tích yêu cầu và tạo implementation plan",
    backstory="Bạn là kiến trúc sư 15 năm kinh nghiệm...",
    llm=ChatAnthropic(model="claude-sonnet-4-20250514"),
    tools=[FileReadTool(), DirectorySearchTool()]
)

coder = Agent(
    role="Backend Developer",
    goal="Viết code theo plan đã duyệt",
    backstory="Bạn là .NET developer chuyên Clean Architecture...",
    llm=ChatAnthropic(model="claude-sonnet-4-20250514"),
    tools=[FileWriteTool(), TerminalTool()]
)

reviewer = Agent(
    role="Code Reviewer",
    goal="Review code theo conventions trong CLAUDE.md",
    ...
)
```

→ Phải viết **prompt riêng** cho từng agent, chọn tools, chọn model.

**b) Định nghĩa Tasks:**
```python
task_plan = Task(
    description="Phân tích yêu cầu: {feature_name}",
    expected_output="Implementation plan dạng markdown",
    agent=planner
)

task_code = Task(
    description="Viết code theo plan",
    expected_output="Source code files",
    agent=coder,
    context=[task_plan]  # ← Phụ thuộc vào task_plan
)
```

→ Phải định nghĩa **dependencies giữa tasks**.

**c) Cài đặt Orchestrator:**
```python
crew = Crew(
    agents=[planner, coder, reviewer],
    tasks=[task_plan, task_code, task_review],
    process=Process.sequential,  # hoặc hierarchical
    verbose=True
)
```

→ Phải chọn **process type**, cấu hình **memory**, **logging**.

#### ✅ So sánh với Single Agent (Claude Code):
```bash
# Chỉ cần:
npm install -g @anthropic-ai/claude-code
cd AppPickleball
claude
# → Done. Agent tự đọc CLAUDE.md, tự hiểu project.
```

### 5.2 Communication Overhead (Chi phí giao tiếp)

Đây là **vấn đề lớn nhất** của Multi-Agent. Hãy xem ví dụ cụ thể:

#### Ví dụ: Task "Thêm API verify-email"

**Single Agent** — 1 conversation:
```
Context: CLAUDE.md (9KB) + relevant files (5KB) = ~14KB
Token usage: ~15,000 tokens
Thời gian: ~2 phút
```

**Multi Agent** — 4 agents, mỗi agent 1 conversation riêng:

```
Agent A (Planner):
  Input:  CLAUDE.md (9KB) + yêu cầu user (1KB)     = 10KB
  Output: Plan (3KB)
  Tokens: ~8,000

Agent B (Coder):
  Input:  Plan (3KB) + CLAUDE.md (9KB) + files (5KB) = 17KB  ← LẶP LẠI CLAUDE.md!
  Output: Code (10KB)
  Tokens: ~20,000

Agent C (Reviewer):
  Input:  Code (10KB) + CLAUDE.md (9KB) + Plan (3KB) = 22KB  ← LẶP LẠI CẢ HAI!
  Output: Review comments (2KB)
  Tokens: ~15,000

Agent D (Tester):
  Input:  Code (10KB) + Review (2KB) + CLAUDE.md (9KB) = 21KB  ← LẠI LẶP!
  Tokens: ~12,000
```

**So sánh:**
```
┌──────────────┬─────────────────┬─────────────────┐
│              │  Single Agent   │  Multi Agent     │
├──────────────┼─────────────────┼─────────────────┤
│ Total tokens │  ~15,000        │  ~55,000 (3.7x) │
│ CLAUDE.md    │  Đọc 1 lần     │  Đọc 4 lần      │
│ Context      │  14KB           │  70KB tổng       │
│ Thời gian    │  ~2 phút       │  ~6 phút         │
│ Chi phí API  │  $0.03          │  $0.11           │
└──────────────┴─────────────────┴─────────────────┘
```

#### Tại sao overhead xảy ra?

```
┌─────────────────────────────────────────────────────┐
│              COMMUNICATION OVERHEAD                  │
│                                                      │
│  1. CONTEXT DUPLICATION (Lặp context)                │
│     Mỗi agent cần project context riêng              │
│     → CLAUDE.md, SQL schema phải gửi nhiều lần       │
│                                                      │
│  2. SERIALIZATION COST (Chi phí serialize)            │
│     Output agent A → serialize thành text             │
│     → gửi cho agent B → B parse lại                  │
│     → Mất thông tin ngữ cảnh trong quá trình          │
│                                                      │
│  3. MISUNDERSTANDING LOOPS (Vòng lặp hiểu sai)       │
│     Agent C review: "Thiếu resource key"             │
│     Agent B fix: thêm key nhưng sai format            │
│     Agent C review lần 2: "Format sai"               │
│     → Nhiều round trips                              │
│                                                      │
│  4. COORDINATION DELAY (Chờ đợi)                     │
│     Agent B PHẢI chờ Agent A xong mới bắt đầu        │
│     → Thời gian = Σ(thời gian mỗi agent)             │
│     → Không phải lúc nào cũng song song được          │
└─────────────────────────────────────────────────────┘
```

#### Khi nào overhead ĐÁNG?

```
✅ ĐÁNG khi:
  - Task rất lớn (refactor 50+ files)
  - Cần expert riêng biệt (Security Agent + Performance Agent)
  - Cần song song xử lý (3 microservices cùng lúc)

❌ KHÔNG ĐÁNG khi:
  - CRUD feature đơn giản
  - Fix bug 1-2 files
  - Thêm 1 API endpoint
  - Project < 100 files
```

---

## 6. So sánh Single Agent vs Multi-Agent

### Bảng so sánh tổng hợp

| Tiêu chí | Single Agent + Skills | Multi-Agent Team |
|---|---|---|
| **Setup time** | 5 phút (CLAUDE.md + workflows) | 2-4 giờ (agents, tasks, orchestrator) |
| **Token cost** | 1x | 3-5x |
| **Tốc độ** | Nhanh | Chậm hơn (coordination) |
| **Chất lượng** | Tốt (với skills tốt) | Rất tốt (peer review) |
| **Debug** | Dễ (1 conversation) | Khó (nhiều agents, logs rời rạc) |
| **Phù hợp** | 90% tasks hàng ngày | 10% tasks phức tạp |

### Kết luận cho AppPickleball

```
AppPickleball hiện tại:
  - ~17 entities, ~17 configurations
  - CQRS pattern rõ ràng
  - Conventions đã document trong CLAUDE.md

→ Single Agent + Skills (Claude Code) = LỰA CHỌN TỐI ƯU
→ Multi-Agent = overkill cho project scale này
```

---

## 7. Áp dụng thực tế cho AppPickleball

### Setup hiện tại (đã hoàn thành)

```
AppPickleball/
├── CLAUDE.md                          ← ✅ Project guide (180 dòng)
├── .agent/
│   └── workflows/
│       ├── create-feature.md          ← ✅ /create-feature
│       ├── create-entity.md           ← ✅ /create-entity
│       ├── add-resource-keys.md       ← ✅ /add-resource-keys
│       ├── fix-ef-warnings.md         ← ✅ /fix-ef-warnings
│       └── debug-runtime.md           ← ✅ /debug-runtime
```

### Cách dùng hàng ngày

```bash
# Mở terminal
cd AppPickleball
claude

# Dùng tự nhiên:
> Thêm API POST api/auth/forgot-password, flow giống resend-verification

# Hoặc dùng workflow:
> /create-feature

# Agent sẽ:
# 1. Đọc CLAUDE.md → hiểu conventions
# 2. Đọc workflow → làm theo từng bước
# 3. Tự build verify → 0 errors
```

### Mở rộng thêm workflows khi cần

Khi project phát triển, bạn có thể thêm:
```
workflows/
├── create-migration.md      ← Tạo EF migration
├── add-event-handler.md     ← Thêm MassTransit consumer
├── create-integration-test.md ← Tạo integration test
└── deploy-staging.md        ← Deploy lên staging
```

---

> **Tóm tắt:** Với project AppPickleball, **Single Agent + Skills** (Claude Code + CLAUDE.md + Workflows) là cách tiếp cận tối ưu nhất. Multi-Agent chỉ cần khi bạn scale lên nhiều microservices và cần xử lý song song.
