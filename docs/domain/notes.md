# Notes Feature Domain

## 1. Domain Concept
The Notes module provides a multi-tier knowledge repository and structured collaborative discussion system. It is modeled as a tree: Repo -> Post -> Comment.

---

## 2. Core Entities & Schema

### 2.1 Repo
- Definition: A top-level repository/folder categorizing related documents.
- Model: `Repo { String name, String status, String? description }`
- ACL Enabled: Yes (`withAcls: true`). Supports team sharing and role-based permissions.
- Storage: Table `repo` in `notes.db`.

### 2.2 Post
- Definition: An individual article or note belonging to a `Repo`.
- Model: `Post { String title, String category, String content, String repoId }`
- Hierarchy: `parentIdField: 'repoId'`.
- Storage: Table `post` in `notes.db`.

### 2.3 Comment
- Definition: Remarks or feedback made on an individual post.
- Model: `Comment { String content, String postId, String? parentId, int? paragraphIndex, String? paragraphHash }`
- Hierarchy: `parentIdField: 'postId'`. Supports nested replies via `parentId`.
- Inline Paragraph Anchoring: `paragraphIndex` and `paragraphHash` allow comments to anchor to specific markdown paragraphs in the post.
- Storage: Table `comment` in `notes.db`.

---

## 3. Permissions & Capabilities

Operation access levels are enforced through `NotesFeatureRequires` implementing `FeaturePermission`:

- `updateRepo`, `updatePost`, `editComment`: Requires `ACLMask.updateOnly` (`0x02`).
- `deleteRepo`, `deletePost`, `deleteComment`: Requires `ACLMask.deleteOnly` (`0x04`).
- `newComment`, `replyComment`: Requires `ACLMask.append2Below` (`0x18`).
- `fullAccess`: Requires `ACLMask.fullAccess` (`0x3F`).

---

## 4. Staged Synchronization

Initial sync and manual refreshes follow a 3-stage pipeline in `onReadySyncAll()`:

1. Stage 1 (0% - 15%): Sync Repos -> Rebuild local repo index -> Sync Repo ACLs.
2. Stage 2 (15% - 75%): Sync Posts (batch size 40) -> Rebuild local post index.
3. Stage 3 (75% - 100%): Sync Comments (batch size 60) -> Rebuild local comment, post, and repo indexes.

---

## 5. Key Source Paths

- Models & Codegen: `lib/models/notes/model.dart`
- Database Provider: `lib/models/notes/db.dart`
- Page Views: `lib/pages/notes/editor_pages.dart`, `lib/pages/notes/view_post.dart`
- Components: `lib/components/notes/view_repos.dart`, `lib/components/notes/view_posts.dart`, `lib/components/notes/markdown_renderer.dart`
