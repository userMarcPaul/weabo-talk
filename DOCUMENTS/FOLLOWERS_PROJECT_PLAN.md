# Followers & Following: Project Plan

**Goal**: Replace the two-way friend system (request → accept) with one-way following,
like Instagram or X. Anyone can follow anyone; nobody has to accept or follow back.

**Status**: Phases 1–5 done (decisions D1–D6 as recommended); phase 6 (deploy) and the
optional phase 7 are next · **Priority**: 🟡 Medium

---

## 1. What changes for users

| Today (friends) | After (followers / following) |
|---|---|
| **Add Friend** sends a request | **Follow** takes effect right away |
| The other person must **Accept** or **Decline** | Nothing to accept |
| **Unfriend** removes the connection for both | **Unfollow** removes only your follow |
| **Friend Requests** page | Removed |
| **My Friends** page | **Followers** and **Following** pages |
| Profile shows **Friends** count | Profile shows **Followers** and **Following** counts |
| "sent you a friend request" / "accepted your friend request" notifications | "**started following you**" notification |
| Search results show "👥 N friends" | Search results show "N followers" |

---

## 2. Decisions to confirm before starting

| # | Question | Recommended |
|---|---|---|
| D1 | Replace friends completely, or keep both systems? | **Replace.** Two systems confuse users and double the code to maintain. |
| D2 | What happens to existing **accepted** friendships? | **Both people follow each other**, so nobody loses a connection. |
| D3 | What happens to **pending** friend requests? | **The sender follows the receiver.** That's what the sender wanted. |
| D4 | What happens to the old friend-request notifications? | **Delete them.** They point to friendships that will no longer exist. |
| D5 | Should the home feed show only people you follow? | **Later, as a separate change** (phase 7). Keep showing all posts for now. |
| D6 | Private accounts (approve followers)? | **Out of scope.** All accounts stay public. |

---

## 3. Data model

### New table: `follows`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | |
| `follower_id` | bigint, not null | The user who follows (FK → `users`) |
| `followed_id` | bigint, not null | The user being followed (FK → `users`) |
| `created_at`, `updated_at` | datetime | |

Indexes:
- unique `(follower_id, followed_id)`, so a user can follow someone only once;
- `followed_id`, for fast follower lists and counts.

### `Follow` model
- `belongs_to :follower` and `belongs_to :followed` (both `class_name: "User"`)
- Validations: uniqueness of `follower_id` scoped to `followed_id`; a user can't follow themselves
- `has_many :notifications, as: :notifiable, dependent: :destroy`
- `after_create_commit`: create a `new_follower` notification for the followed user. It is broadcast live, like the existing notifications.

### `User` associations
```ruby
has_many :active_follows,  class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
has_many :passive_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
has_many :following, through: :active_follows,  source: :followed
has_many :followers, through: :passive_follows, source: :follower

def following?(user) = active_follows.exists?(followed: user)
```

### Moving existing data (one migration, run on deploy)

| Old `friendships` row | New `follows` row(s) |
|---|---|
| `accepted` | `user_id → friend_id`. Accepted friendships are already stored in both directions, so each pair becomes a mutual follow. |
| `pending` | `user_id → friend_id` (the sender follows the receiver) |
| `blocked` | Dropped (not used anywhere in the app) |

- Old notifications with type `friend_request_sent` or `friend_request_accepted` are deleted.
- **The `friendships` table is dropped in a second, later migration**, after the new system has been checked in production. Until then the old data stays in place as a fallback.
- The same migration **removes the `friendships` foreign keys to `users`**. Without the `Friendship` model nothing deletes those rows anymore, so the foreign keys would block deleting an account that still has old friendship rows.

---

## 4. Routes

| Method | Path | Action |
|---|---|---|
| POST | `/profiles/:username/follow` | `follows#create` (follow) |
| DELETE | `/profiles/:username/follow` | `follows#destroy` (unfollow) |
| GET | `/profiles/:username/followers` | `follows#followers` |
| GET | `/profiles/:username/following` | `follows#following` |

Removed: `resources :friendships` and `GET /friend-requests`. Both old URLs **redirect** to the
user's Following page instead of returning 404, in case someone bookmarked them.

---

## 5. Work plan

### Phase 1: Database & model (≈ 2–3 h)
- [x] Migration: create `follows` with indexes and foreign keys
- [x] Migration: copy friendships into follows (section 3) and delete old friend notifications
- [x] `Follow` model, validations, `new_follower` notification
- [x] `User` associations and `following?`
- [x] Add `new_follower` to `Notification::NOTIFICATION_TYPES`
- [x] Model tests: follow, unfollow, no self-follow, no duplicates, notification created

### Phase 2: Follow / Unfollow (≈ 2 h)
- [x] `FollowsController#create` / `#destroy`, signed-in users only; responds with a Turbo Stream and has an HTML fallback
- [x] `follows/_follow_button.html.erb`: **Follow** / **Following**, with **Unfollow** on click or hover. Keyed by `dom_id(user, :follow_button)` so it updates in place on any page.
- [x] Turbo Stream templates: replace the button and the profile's follower count
- [x] Notification partial: "**username** started following you" with a View Profile link
- [x] Controller tests: follow, unfollow, can't follow yourself, signed-out users are redirected to sign in

### Phase 3: Pages & copy (≈ 2 h)
- [x] Profile (`profiles/show`): **Followers** and **Following** counts (each links to its list) and the follow button
- [x] **Followers** and **Following** list pages, reusing the friend list item (renamed `Follows::UserItemComponent`) with a follow button instead of **Remove**, 20 per page
- [x] Navbar (`shared/_navbar`): replace **Friends** / **My Friends** with **Following** / **Followers**, and remove the friend-request red dot (bar and profile menu)
- [x] Search: `friends_count` → `followers_count` in `Users::SearchService` and `user_search_controller.js`
- [x] Copy: change "friends" wording in `pages/home`, `posts/index`, `confirmations/pending`, `users/confirmations/confirmed`
- [x] Keep the pages responsive (360 px – 1440 px), as checked in the responsiveness pass

### Phase 4: Remove the friend system (≈ 1 h)
- [x] Delete `Friendship` model, `FriendshipsController`, `app/views/friendships/*`, `Friendships::FriendItemComponent`
- [x] Delete the unused `friend_button_controller.js` and its registration in `controllers/index.js`
- [x] Remove friendship associations from `User`, and the friend types from `Notification`
- [x] Routes: remove friendships, add the redirects (section 4)
- [x] Replace `friendships_controller_test.rb` / `friendship_test.rb` with follow tests; update the posts and notifications tests that use friendships

### Phase 5: Checks (≈ 1–2 h)
- [x] Full test suite and RuboCop pass
- [x] Browser check (Firefox, phone and desktop):
  - follow and unfollow update without a page reload
  - counts change
  - the notification arrives live
  - lists open
  - old URLs redirect
- [x] Migration check on test data in development: friend pairs became mutual follows, pending requests one follow, blocked rows dropped, friend notifications deleted, accounts with old rows can still be deleted

### Phase 6: Deploy
- [ ] **Back up the Supabase database first** (`pg_dump` with the Session pooler connection string)
- [ ] Merge and deploy. Render runs the migrations automatically (`db:prepare` in `bin/docker-entrypoint`).
- [ ] Check in production: follow, unfollow, notifications, profile counts
- [ ] After about a week without problems: add the migration that drops `friendships`

### Phase 7 (optional, separate PR): Following feed
- [ ] Home feed shows your own posts plus posts from people you follow
- [ ] If you follow nobody yet: show all posts with a "Find people to follow" prompt

---

## 6. Files affected

| Area | Files |
|---|---|
| **New** | `db/migrate/*_create_follows.rb`, `db/migrate/*_move_friendships_to_follows.rb`, `app/models/follow.rb`, `app/controllers/follows_controller.rb`, `app/views/follows/*`, `app/components/follows/user_item_component.*`, `test/models/follow_test.rb`, `test/controllers/follows_controller_test.rb` |
| **Changed** | `app/models/user.rb`, `app/models/notification.rb`, `app/controllers/profiles_controller.rb`, `app/services/users/search_service.rb`, `app/javascript/controllers/user_search_controller.js`, `app/javascript/controllers/index.js`, `app/views/profiles/show.html.erb`, `app/views/shared/_navbar.html.erb`, `app/views/notifications/_notification.html.erb`, `app/views/pages/home.html.erb`, `app/views/posts/index.html.erb`, `app/views/confirmations/pending.html.erb`, `app/views/users/confirmations/confirmed.html.erb`, `config/routes.rb`, `test/controllers/posts_controller_test.rb`, `test/controllers/notifications_controller_test.rb` |
| **Removed** | `app/models/friendship.rb`, `app/controllers/friendships_controller.rb`, `app/views/friendships/*`, `app/components/friendships/*`, `app/javascript/controllers/friend_button_controller.js`, `test/models/friendship_test.rb`, `test/controllers/friendships_controller_test.rb` |

---

## 7. Risks

| Risk | How it's handled |
|---|---|
| Data loss during the switch | The old `friendships` table is kept until the new system is confirmed in production, and the database is backed up before deploy |
| Old links (`/friendships`, `/friend-requests`) break | They redirect to the Following page |
| Notifications pointing to deleted friendships crash the notification list | Old friend notifications are deleted in the same migration |
| The live notification badge breaks | `new_follower` uses the same broadcast as the other notifications; checked in phase 5 |
| Supabase free-tier space (500 MB) | One follow row is about 100 bytes, so even 100,000 follows is about 10 MB |

---

## 8. Out of scope
- Private accounts and follow requests (D6)
- Blocking users
- "Suggested people to follow"
- Following feed (phase 7, separate PR)
