# El Marshall's Dev Portfolio

My portfolio site, a Rails 8 app. Besides the portfolio pages it hosts a couple of hobby projects
as their own sections:

1. Portfolio pages (including a showcase of my Android apps)
2. Sudoku hobby project
3. Habit Saver hobby project

## App Areas

### Portfolio

- Purpose: personal portfolio/home content
- Routes:
  - / (root)
  - /portfolio
- Sections: name card, hobby projects, Android apps, credits
- Android app screenshots live in `app/assets/images/android/`

- To Do:
  - Add about section
  - Add picture of me
  - Make mobile-friendly version

### Sudoku hobby project

- Purpose: playable and solvable Sudoku experience
- Routes:
  - /sudoku
- Features:
  - Puzzle generation and solving
  - Optional live puzzle fetch from You Do Sudoku API (falls back to local JSON puzzles if key is not configured)
  - Interactive UI with Turbo/Stimulus-style updates
  - JSON puzzle data source

- To DO:
  - Add panel with description of functionality
  - Improve puzzle generator efficiency

### Habit Saver hobby project

- Purpose: habit tracking and savings-oriented workflow
- Routes:
  - /habit_saver (authenticated area)
  - /habit_saver/login
- Auth:
  - First-party email/password sign in and sign up flow
  - Persisted users and auth sessions

- To Do:
	- lots, this one's still in dev.

## Prerequisites

- Ruby compatible with Rails 8.1.3
- Bundler
- PostgreSQL
- Node.js (optional, for frontend tooling if needed)

## Local Setup

1. Clone and install gems:

```sh
git clone <repo-url>
cd el-dev-portfolio
bundle install
```

1. Setup database:

```sh
bin/rails db:setup
```

1. Optional: enable You Do Sudoku API integration (live puzzles):

```sh
export YOU_DO_SUDOKU_API_KEY="<your-you-do-sudoku-api-key>"
```

Or store it in encrypted Rails credentials as `you_do_sudoku.api_key`.

The app calls `https://you-do-sudoku-api.vercel.app/api` with the `x-api-key` header when this key is present.

1. Optional Sudoku puzzle regeneration:

```sh
rake puzzles:generate_json
```

1. Optional Sudoku puzzle fetch from You Do Sudoku API:

```sh
rake puzzles:fetch_json_from_api
```

This task skips puzzles that already exist in the target difficulty bucket.

1. Start server:

```sh
bin/rails s
```

1. Visit:

- Portfolio: <http://localhost:3000/>
- Sudoku: <http://localhost:3000/sudoku>
- Habit Saver Login: <http://localhost:3000/habit_saver/login>

## Habit Saver Authentication Setup

Habit Saver now uses first-party email/password authentication and does not require any third-party OAuth provider.

### Steps

1. Run migrations to ensure auth columns exist:

```sh
bin/rails db:migrate
```

1. Open Habit Saver login page:

<http://localhost:3000/habit_saver/login>

1. Create an account with email + password in the Sign Up form.

1. Use the Log In form for subsequent sign-ins.

### Notes

- Passwords are stored securely via bcrypt (`has_secure_password`).
- Sessions are persisted in `habit_saver_auth_sessions`.
- No external identity provider is needed.

## Testing

Run all tests:

```sh
bin/rails test
```

Run a focused Habit Saver auth test:

```sh
bin/rails test test/models/habit_saver/auth_session_test.rb
```

## Deployment

- Dockerfile is included for containerized deployment.
- See config/deploy.yml for deployment configuration.
- The Kamal service, image and storage volume are still named `sudoku_a` from before the repo was
  renamed. Renaming them would start a new container and a new, empty storage volume, so they're
  left as they are.
