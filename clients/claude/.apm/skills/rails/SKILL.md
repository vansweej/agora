---
name: rails
description: >
  Use when working in a Ruby on Rails project or when the task involves Rails
  conventions, ActiveRecord, controllers, views, or migrations. Triggers on:
  rails, activerecord, migration, controller, model, view, routes, erb, turbo,
  stimulus, hotwire, sidekiq, actionmailer, activejob, devise.
---

<!-- DO NOT EDIT — generated from .apm/skills/rails/SKILL.md by agora/renderers/opencode-to-claude.md -->

# Ruby on Rails

Framework-specific rules for Rails projects. Load this skill when working in
any repository that uses Rails (presence of `config/application.rb`).

## Core Principles

- Convention over configuration — follow Rails defaults
- Fat models, skinny controllers
- Keep business logic in models, service objects, or POROs — never in controllers or views
- Prefer the Rails way; deviate only with good reason

## Project Structure

- Follow standard Rails directory layout (`app/`, `config/`, `db/`, `lib/`, `test/` or `spec/`)
- Group domain logic under `app/models/`, `app/services/`, `app/jobs/`
- Use concerns (`app/models/concerns/`, `app/controllers/concerns/`) sparingly and only for shared, cohesive behaviour
- Keep view partials small and focused

## ActiveRecord & Database

- Always use migrations for schema changes; never modify `schema.rb` by hand
- Add database-level constraints (NOT NULL, uniqueness indexes, foreign keys) alongside model validations
- Use `has_many :through` over `has_and_belongs_to_many`
- Avoid N+1 queries: use `includes`, `preload`, or `eager_load`
- Keep scopes in the model; avoid raw SQL in controllers
- Use `find_each` / `in_batches` for large datasets
- Index foreign keys and columns used in `WHERE` / `ORDER BY`
- Prefer `create!` / `save!` / `update!` (bang versions) in non-user-facing code to surface errors immediately

## Controllers

- Keep actions to the 7 RESTful defaults; add custom actions only when necessary
- Use `before_action` for shared setup (e.g. `set_resource`)
- Use strong parameters (`params.require(...).permit(...)`)
- Respond with appropriate HTTP status codes
- Avoid logic in controllers — delegate to models or service objects

## Routing

- Use resourceful routes (`resources`, `resource`)
- Namespace admin routes under `namespace :admin`
- Use shallow nesting to avoid deeply nested routes
- Keep `routes.rb` readable; extract route groups with `draw` files for large apps

## Views & Frontend

- Use Hotwire (Turbo + Stimulus) for interactivity — avoid full SPA unless explicitly required
- HTML-over-the-wire: send HTML fragments, not JSON
- Keep ERB templates logic-free; use helpers or presenters for display logic
- Use partials for reusable components; pass locals explicitly (avoid instance variables in partials)
- Progressive enhancement: the app should work without JS, then layer interactivity

### Turbo Drive

- Turbo Drive is on by default for all navigation; avoid disabling it
- Use `data-turbo="false"` sparingly, only when a full reload is truly needed
- Use `data-turbo-method` for non-GET links (e.g. delete buttons)
- Use `data-turbo-confirm` for destructive actions
- Handle redirects with `redirect_to ..., status: :see_other` (303) after non-GET requests

### Turbo Frames

- Wrap independently-updatable sections in `turbo_frame_tag` with `dom_id(resource)`
- Frame IDs must be unique on the page
- Use `src` attribute for lazy-loaded frames; `loading: :lazy` for below-the-fold content
- Set `target: "_top"` on links that should break out of the frame
- Keep frames small — one concern per frame

```erb
<%= turbo_frame_tag dom_id(post) do %>
  <%= render post %>
<% end %>
```

### Turbo Streams

- Use Turbo Streams for multi-target updates that Frames cannot express
- Seven actions: `append`, `prepend`, `replace`, `update`, `remove`, `before`, `after`
- Respond to form submissions with `format.turbo_stream` in the controller
- Always provide a `format.html` fallback for graceful degradation
- Use `turbo_stream.broadcast_*` (via ActionCable) for real-time updates

```erb
<%= turbo_stream.append "comments", partial: "comments/comment", locals: { comment: @comment } %>
```

### Broadcasting

- Broadcast from models using `broadcasts_to` or `broadcasts`
- Keep broadcast partials simple; they render without a request context
- Use `broadcast_replace_later_to` / `broadcast_append_later_to` for background job safety
- Target streams with descriptive names: `turbo_stream_from @post, :comments`

```ruby
class Comment < ApplicationRecord
  belongs_to :post
  broadcasts_to :post, inserts_by: :prepend
end
```

### Turbo Morphing (Turbo 8+)

- Use `<meta name="turbo-refresh-method" content="morph">` for page-level morphing
- Use `<meta name="turbo-refresh-scroll" content="preserve">` to keep scroll position
- Add `data-turbo-permanent` to elements that must not be morphed (e.g. video players, open modals)
- Combine with broadcasts for real-time morph updates

### Stimulus

- Each controller lives in `app/javascript/controllers/` as `<name>_controller.js`
- Keep controllers small (< 50 lines); one responsibility per controller
- Prefer Stimulus targets and values over `querySelector`
- Controller files: `snake_case_controller.js`; data attributes: `data-controller="kebab-case"`
- Actions: `data-action="click->clipboard#copy"`
- Values: `data-clipboard-url-value="/api/copy"`
- Use `connect()` / `disconnect()` lifecycle callbacks for setup/teardown
- Use Values API for configuration passed from HTML; avoid hardcoding
- Use Outlets to communicate between controllers
- Never fetch JSON to render client-side — use a Turbo Frame or Stream instead

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]
  static values = { url: String }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.textContent)
  }
}
```

### Asset Pipeline

- Use importmap-rails (default in Rails 7+) for JS; pin packages with `bin/importmap pin <package>`
- Use Propshaft (or Sprockets) for CSS and static assets
- Prefer Tailwind CSS or vanilla CSS; avoid CSS-in-JS

## Service Objects & POROs

- Extract complex business logic into service objects under `app/services/`
- Service objects should have a single public method (e.g. `call`)
- Return a Result object or use exceptions for control flow — never return mixed types
- Name services as actions: `CreateUser`, `ProcessPayment`, `SendNotification`

## Background Jobs

- Use ActiveJob with Sidekiq (or the configured adapter)
- Keep jobs idempotent — safe to retry
- Pass IDs, not full objects, as arguments
- Set appropriate queue and retry configuration

## Mailers

- Keep mailer methods thin; prepare data in the caller
- Use `deliver_later` (async) by default; `deliver_now` only when synchronous delivery is required
- Preview mailers in development with `ActionMailer::Preview`

## Authentication & Authorization

- Use Devise (or the project's chosen auth library) for authentication
- Use Pundit or CanCanCan for authorization policies
- Never roll custom auth unless there is a strong, explicit reason

## Security

- Never trust user input: sanitize, validate, and use strong parameters
- Use `html_safe` and `raw` only when absolutely necessary; prefer Rails auto-escaping
- Protect against CSRF (enabled by default); do not skip `verify_authenticity_token`
- Store secrets in credentials (`rails credentials:edit`) or environment variables — never in source
- Avoid mass-assignment vulnerabilities: always permit explicitly

## Testing

- Use RSpec with FactoryBot (or Minitest with fixtures — follow the project)
- Write request specs for controller behaviour; model specs for validations and logic
- Use `shoulda-matchers` for concise model specs
- Test jobs, mailers, and services in isolation
- Run `bundle exec rspec` (or `rails test`) before declaring done
- Measure coverage with `simplecov`; target >= 90%

## Migrations

- Migrations must be reversible when possible (use `change`; fall back to `up`/`down`)
- Add comments to non-obvious columns with `comment:`
- For large tables, consider `safety_assured` blocks with `strong_migrations` gem
- Never remove a column without first ignoring it (`self.ignored_columns`)

## Tooling

- Run `bin/rails db:migrate` after writing migrations
- Run `rubocop -A` before declaring done
- Run `bundle exec rspec` or `bin/rails test` before declaring done
- Use `bin/rails console` for interactive debugging
- Always run inside the Nix dev shell if a `flake.nix` is present:
  `nix develop --command <cmd>`

## Code Review

- Flag N+1 queries (missing `includes`)
- Flag business logic in controllers or views
- Flag missing database indexes on foreign keys
- Flag missing validations for non-nullable columns
- Flag `skip_before_action :verify_authenticity_token` without justification
- Flag raw SQL that could be expressed as ActiveRecord queries
- Flag Stimulus controllers that fetch JSON and render DOM (use Turbo instead)
- Flag Turbo Frame tags missing an `id`
- Flag forms that redirect without `status: :see_other` (breaks Turbo Drive)
- Flag broadcasts without a matching `turbo_stream_from` subscription in the view

## Code Generation

- Always generate runnable code
- Use Rails generators where appropriate (`rails g model`, `rails g migration`)
- Include all necessary `require` statements
- Follow existing patterns in the codebase for consistency
