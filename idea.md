oioGit – Git Repository Monitor for macOS
Tổng quan
oioGit là một ứng dụng menu bar macOS native (SwiftUI), giúp developer theo dõi trạng thái nhiều Git repository cùng lúc mà không cần mở terminal hay Git client. Ứng dụng chạy nền, nhẹ, và cung cấp thông tin realtime ngay trên thanh menu bar.

Đối tượng người dùng
Developer làm việc với nhiều project/repo đồng thời — freelancer quản lý nhiều client, team lead review nhiều repo, hoặc developer có cả project chính lẫn side project.

Kiến trúc kỹ thuật
Tech Stack chính:
* SwiftUI + AppKit (menu bar app, NSStatusItem)
* SwiftData hoặc CoreData (lưu danh sách repo, settings)
* DispatchSource.makeFileSystemObjectSource hoặc FSEvents API (theo dõi thay đổi file trong .git)
* Process API (chạy lệnh git CLI từ Swift)
* UserNotifications framework (cảnh báo)
* Combine (reactive data flow)
Mô hình hoạt động:


┌─────────────────────────────────────────────┐
│              Menu Bar Icon                   │
│   (icon đổi màu theo trạng thái tổng hợp)   │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─── GitMonitorService ──────────────────┐ │
│  │                                        │ │
│  │  FSEvents / FileWatcher                │ │
│  │     ↓ phát hiện thay đổi .git/         │ │
│  │  GitCommandRunner                      │ │
│  │     ↓ chạy git status, git log...      │ │
│  │  RepoStateModel                        │ │
│  │     ↓ cập nhật UI qua @Observable      │ │
│  │                                        │ │
│  └────────────────────────────────────────┘ │
│                                             │
│  ┌─── SwiftData ──────────────────────────┐ │
│  │  RepoConfig (path, alias, settings)    │ │
│  │  NotificationRules                     │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘

Tính năng chi tiết
1. Menu Bar Icon thông minh
Icon trên menu bar thay đổi theo trạng thái tổng hợp của tất cả repo:
* Xanh lá — tất cả repo sạch, không có gì pending
* Vàng — có file thay đổi chưa commit hoặc commit chưa push
* Đỏ — có conflict hoặc repo ở trạng thái detached HEAD
* Số badge — hiển thị tổng số repo cần chú ý
2. Popover Dashboard
Click vào icon sẽ mở một popover SwiftUI hiển thị danh sách repo dạng card:
Mỗi repo card hiển thị:
* Tên repo (alias hoặc folder name)
* Branch hiện tại (ví dụ: main, feature/login)
* Trạng thái: ✓ Clean / 3 modified / 1 conflict
* Commits ahead/behind remote: ↑2 ↓5
* Stash count nếu có: 📦 2 stashes
* Thời gian cập nhật cuối
3. Repo Detail View
Click vào một repo card sẽ mở detail view:
* Changed Files tab — danh sách file modified/added/deleted, grouped theo staged và unstaged
* Commit Log tab — 20 commit gần nhất với hash, message, author, thời gian
* Branch tab — danh sách branch local/remote, branch nào đang active
* Quick Actions — nút mở Terminal tại repo, mở trong VS Code / Xcode, copy path
4. Quick Actions từ menu bar
Không cần mở detail, right-click repo card để:
* Mở Terminal / IDE tại thư mục repo
* Copy branch name hiện tại
* Copy đường dẫn repo
* Pull latest (chạy git pull nhanh)
* Tạm ẩn repo khỏi dashboard
5. Hệ thống thông báo
Cấu hình notification cho từng repo hoặc toàn cục:
* Cảnh báo khi xuất hiện merge conflict
* Cảnh báo khi remote có commit mới (behind > 0)
* Nhắc nhở khi có uncommitted changes quá lâu (ví dụ: 2 giờ)
* Nhắc nhở khi unpushed commits quá lâu
* Cảnh báo khi branch bị detached HEAD
6. Quản lý Repo
* Thêm repo bằng drag-and-drop thư mục vào app
* Quét tự động: chọn một thư mục cha, app tìm tất cả .git bên trong
* Gán alias / nhóm cho repo (ví dụ: nhóm "Client A", "Side Projects")
* Sắp xếp theo tên, trạng thái, hoặc thời gian thay đổi
7. Settings
* Tần suất polling (bổ sung cho FSEvents): 30s / 1m / 5m
* Đường dẫn đến git binary (mặc định /usr/bin/git, hỗ trợ Homebrew path)
* Launch at login toggle
* Chọn IDE mặc định để mở repo
* Dark/Light mode (theo system)
* Giới hạn số repo tối đa để tránh tốn tài nguyên

Cấu trúc project đề xuất


oioGit/
├── App/
│   ├── oioGitApp.swift          # @main, NSStatusItem setup
│   └── AppDelegate.swift          # Menu bar lifecycle
├── Models/
│   ├── RepoConfig.swift           # SwiftData model
│   ├── RepoState.swift            # Runtime state (@Observable)
│   ├── GitStatus.swift            # Parsed git status
│   └── CommitInfo.swift           # Commit data model
├── Services/
│   ├── GitCommandRunner.swift     # Chạy git CLI qua Process
│   ├── FileWatcherService.swift   # FSEvents wrapper
│   ├── RepoMonitorService.swift   # Orchestrator chính
│   ├── NotificationService.swift  # UserNotifications
│   └── RepoScannerService.swift   # Quét thư mục tìm repo
├── Views/
│   ├── MenuBarPopover/
│   │   ├── DashboardView.swift    # Danh sách repo cards
│   │   ├── RepoCardView.swift     # Một repo card
│   │   └── StatusBadgeView.swift  # Badge trạng thái
│   ├── Detail/
│   │   ├── RepoDetailView.swift   # Tab view chi tiết
│   │   ├── ChangedFilesView.swift
│   │   ├── CommitLogView.swift
│   │   └── BranchListView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── RepoManagerView.swift
│       └── NotificationSettingsView.swift
└── Utilities/
    ├── GitOutputParser.swift      # Parse git CLI output
    ├── DateFormatter+Ext.swift
    └── Constants.swift

Các lệnh Git cần dùng
Mục đích	Lệnh
Trạng thái tổng quát	git status --porcelain
Branch hiện tại	git branch --show-current
Commits ahead/behind	git rev-list --left-right --count HEAD...@{upstream}
Commit log	git log --oneline -20
Danh sách branch	git branch -a
Kiểm tra conflict	git diff --name-only --diff-filter=U
Stash count	git stash list | wc -l
Fetch remote	git fetch --all --quiet
Lộ trình phát triển
Phase 1 — MVP - Menu bar icon, thêm repo thủ công, hiển thị branch + status cơ bản, popover dashboard với danh sách repo card.
Phase 2 — Monitoring - FSEvents watcher, auto-refresh khi .git thay đổi, ahead/behind counter, fetch remote định kỳ.
Phase 3 — Notifications & Detail - Detail view với changed files và commit log, hệ thống notification, quick actions (mở terminal/IDE).
Phase 4 — Polish - Auto-scan thư mục, nhóm repo, settings đầy đủ, launch at login, animation và UI polish, icon design.
Phase 5 — Nâng cao - Keyboard shortcut global, widget macOS, theo dõi CI/CD status qua GitHub API, mini diff viewer inline.

Thách thức cần lưu ý
* Performance — theo dõi quá nhiều repo cùng lúc sẽ tốn CPU vì phải spawn nhiều git process. Nên đặt giới hạn (ví dụ: 15–20 repo) và dùng throttle/debounce khi FSEvents fire liên tục.
* Sandbox — nếu phát hành trên Mac App Store, Sandbox sẽ hạn chế quyền truy cập file system. Cân nhắc phát hành ngoài App Store hoặc dùng Security-Scoped Bookmarks.
* Git binary — không phải máy nào cũng có git cùng path. Cần detect hoặc cho user cấu hình.
* Large repo — repo lớn (monorepo) chạy git status có thể chậm. Cần timeout và hiển thị trạng thái "đang quét".
