# Code Review Findings

**Date:** 2026-10-18
**Commit reviewed:** `75e0e64` (main)
**Method:** Source read-through only. Ruby wasn't installed in the review environment, so the tests weren't run and the app wasn't booted.

---

## Project Summary

WeaboTalk is a social network for anime fans, built with Ruby on Rails 8.1, PostgreSQL, Hotwire (Turbo + Stimulus) and Tailwind.

- **Accounts:** sign-up and login through Devise, with email confirmation and password reset (custom mailer that sends through Gmail SMTP).
- **Profiles:** each user gets one automatically on sign-up, with username, bio, avatar and banner.
- **Posts:** title, text and multiple images, with a draft/publish workflow (`Posts::DraftService`).
- **Engagement:** likes, 9 emoji reactions, and comments with replies.
- **Friends:** send, accept and decline friend requests.
- **Notifications:** saved to the database and pushed over Action Cable. Comment notifications run through a background job.
- **User search:** by username or bio.

Test coverage is minimal: [test/models/user_test.rb](test/models/user_test.rb) is the only test file.

---

## Problems

### Things that crash or don't work at all

| # | Problem | Location | Details |
|---|---------|----------|---------|
| 1 | App won't start in production | [app/controllers/forms_controller.rb:4](app/controllers/forms_controller.rb#L4) | `skip_authentication_requirement!` is called as a class method but only defined as a private instance method, which raises `NoMethodError`. Production loads every class at startup (`eager_load = true`), so the app crashes on boot. In development it crashes whenever `/forms/validate` is hit. Commit `b7c580a` fixed the same bug in `UsersController` but missed this file. |
| 2 | Sign-up fails for emails with a dot or a `+` | [app/models/user.rb:42](app/models/user.rb#L42) | The username is made from the part before the `@`, so `john.doe@gmail.com` gives the username `john.doe`. Profile usernames only allow `[a-zA-Z0-9_]`, so `Profile.create!` raises an error and sign-up returns a 500. Names shorter than 3 characters or longer than 30 fail the same way. |
| 3 | Password reset emails fail | [app/mailers/users/user_mailer.rb:19](app/mailers/users/user_mailer.rb#L19) | `reset_password_url(user, reset_password_token: token)` is called, but the helper at line 40 expects `token:`, which raises `ArgumentError`. `unlock_url` has the same mismatch, but `:lockable` isn't enabled, so it never runs. |
| 4 | User search always errors | [app/services/users/search_service.rb:42](app/services/users/search_service.rb#L42) | `.sort_by_relevance(@query)` is chained onto a database query, but it's a private method of the service, which raises `NoMethodError`. The HTML version of the search page also has no error handler ([app/controllers/users_controller.rb:21-25](app/controllers/users_controller.rb#L21-L25)), so it raises a second error on top. |
| 5 | Real-time notifications never arrive | [app/channels/application_cable/connection.rb:14](app/channels/application_cable/connection.rb#L14) | The connection reads `cookies.signed[:user_id]`, which Devise never sets, so every connection is rejected. Also, nothing in `app/javascript` subscribes to `NotificationsChannel`. |
| 6 | The "Decline" friend request button returns a 404 | [app/controllers/friendships_controller.rb:52](app/controllers/friendships_controller.rb#L52) | `destroy` only looks up requests the current user *sent* (`current_user.friendships`), but the person declining is the one who *received* the request. |

### Security and privacy

| # | Problem | Location | Details |
|---|---------|----------|---------|
| 7 | Anyone can delete anyone else's reaction | [app/controllers/reactions_controller.rb:27](app/controllers/reactions_controller.rb#L27) | `@post.reactions.find(params[:id])` doesn't check who owns the reaction. Any signed-in user can delete any reaction. |
| 8 | Drafts are visible to other people | [app/controllers/profiles_controller.rb:12](app/controllers/profiles_controller.rb#L12), [app/controllers/posts_controller.rb:95](app/controllers/posts_controller.rb#L95) | Profile pages list every post, drafts included. `posts#show` also opens any draft by its ID, without logging in. |

### Smaller bugs

| # | Problem | Location | Details |
|---|---------|----------|---------|
| 9 | Accepting a friend request sends a fake "friend request" notification | [app/models/friendship.rb:74](app/models/friendship.rb#L74) | Creating the reverse friendship triggers the `after_create :notify_friend_request` callback, so the original requester gets a "friend request" notification from the person who just accepted them. |
| 10a | Undefined route helper on publish failure | [app/controllers/posts_controller.rb:88](app/controllers/posts_controller.rb#L88) | `drafts_path` should be `drafts_posts_path`. |
| 10b | Undefined method on reaction HTML fallback | [app/controllers/reactions_controller.rb:20](app/controllers/reactions_controller.rb#L20) | `redirect_to root` should be `redirect_to root_path`. |
| 10c | Missing template on comment error | [app/controllers/comments_controller.rb:22](app/controllers/comments_controller.rb#L22) | `render :new` points to `comments/new`, which doesn't exist. |

### Cleanup (low priority)

| # | Problem | Details |
|---|---------|---------|
| 11a | Empty `User.last` file at the repo root | It's tracked in git and looks like it was created by accident. |
| 11b | `config/credentials.yml.enc.bak` is tracked | It's encrypted, so it isn't a direct leak, but it's an old copy of the credentials that doesn't need to be in the repo. |
| 11c | `sidekiq` gem is unused | Jobs use the Rails default adapter or Solid Queue. Nothing sets the job adapter to Sidekiq. |

---

## Suggested Order

1. Fix #1 to #4 first. Each is a small, contained change, and together they unblock booting, sign-up, password reset and search.
2. Fix #6 to #8 next (broken decline button, reaction ownership, draft privacy).
3. #5 needs two parts: a one-line server fix (use `env["warden"].user` in the connection) and new JavaScript that subscribes to the channel and shows notifications on the page.
4. #9 to #11 whenever convenient.
5. Add tests for each fix. Right now only the `User` model has tests.
