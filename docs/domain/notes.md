# Notes Feature Domain

## 1. Domain Concept
The Notes module provides a structured knowledge base and collaborative discussion system modeled as a hierarchical tree: `Repo` (notebook) -> `Post` (article) -> `Comment` (block/paragraph annotation & nested discussion).

---

## 2. Core Entities & Schema

### 2.1 Repo (笔记本 / 知识库)
- **Definition**: Top-level notebook container categorizing articles, supporting multi-member ACL sharing and friend subscriptions.
- **Model**: `Repo { String name, String status, String? description }`
- **Drift Table**: `RepoTable` -> table `repo` in `app_v2.db`.
- **Classification**:
  - `watchMyRepos(userId)`: Notebooks owned by the authenticated user (`owner == userId`).
  - `watchSubscribedRepos(userId)`: Notebooks shared with/subscribed by the user (`owner != userId`).

### 2.2 Post (文章 / 便签)
- **Definition**: Markdown document belonging to a specific `Repo`.
- **Model**: `Post { String title, String category, String content, String repoId }`
- **Drift Table**: `PostTable` -> table `post` in `app_v2.db` (`parent_id = repoId`).
- **Metadata**: Carries `color_tag` (`ColorTag`), `sync_status` (`pending`, `synced`, `archived`), and timestamps.

### 2.3 Comment (批注 / 讨论)
- **Definition**: Nested tree discussion entry anchored to a Post or a specific block within a Post.
- **Model**: `Comment { String content, String postId, String? parentId, int? paragraphIndex, String? paragraphHash }`
- **Drift Table**: `CommentTable` -> table `comment` in `app_v2.db` (`parent_id = postId`).
- **Hierarchy**: Top-level comments have `parentId == null`; nested replies point to parent comment ID.

---

## 3. Key Capabilities & Invariants

1. **Stable Block Annotation (ADR-0007)**:
   - Comments bind to stable paragraph/block anchors (`paragraphIndex`, `paragraphHash`).
   - UI renders multi-level nested discussions via `CommentTreeNode` with expandable/collapsible reply trees (`CommentListWidget`).
2. **Category & Unread State Management**:
   - Posts support batch archiving and marking all as read (`markPostsAsArchived`).
   - Group-level badges compute unread posts and pending comments per category.
3. **Fine-Grained Permissions**:
   - Enforced via `NotesFeatureRequires` backed by `ACLMask`:
     - Edit repo/post: requires `updateOnly` (`0x02`).
     - Delete repo/post: requires `deleteOnly` (`0x04`).
     - Add/reply comment: requires `append2Below` (`0x18`).
     - Delegated admin: requires `fullAccess` (`0x3F`).
4. **Adaptive Workspace**:
   - Desktop (>= 800px): Three-pane Master-Detail workspace (Repos -> Posts -> Editor / ViewPost with inline comments).
   - Mobile: Standard navigation stack with push/pop routing via `go_router`.

---

## 4. Key Source Paths

- **Domain Model**: `app/lib/models/notes/model.dart`
- **Data Repository**: `app/lib/data/repositories/notes_repository.dart` (`NotesRepository`)
- **State Management**: `app/lib/presentation/notes/notes_providers.dart` (Riverpod Notifiers & StreamProviders)
- **Presentation Components**:
  - Main Workspace: `app/lib/presentation/notes/modern_notes_view.dart`
  - Inline Comments: `app/lib/presentation/notes/comment_widgets.dart`
  - Markdown Toolbar: `app/lib/presentation/notes/markdown_editor_toolbar.dart`
  - ACL Management: `app/lib/presentation/notes/repo_acl_dialog.dart`
  - Fast Switcher: `app/lib/presentation/notes/repo_quick_switcher.dart`
- **Route Screens**: `app/lib/pages/notes/editor_pages.dart`, `app/lib/pages/notes/view_post.dart`
