# Changelog

## 0.2.0 (2026-07-11)

### Breaking changes

- Routes restructured:
  - Join endpoints moved from `/groups/join` to `/join` (matches documented API).
  - Invite creation is now a standard nested route: `POST /groups/:group_id/invites` (was a `member` route using `:id`).
  - Member routes now use `:user_id` as the path parameter (`/groups/:group_id/members/:user_id`).
  - Unused `new` / `edit` routes are no longer generated.
- `Groupable::Group` no longer defines `default_scope { where(active: true) }`.
  Use the `active` scope (provided by `GroupBehavior`) or filter with `where(active: true)` explicitly.
- Removed unused `has_secure_password` from `Groupable::Group`, along with the
  `auth_name` / `password_digest` columns from the initial migration.
- Removed unused configuration options: `groups_table_name`, `members_table_name`,
  `users_table_name` and the derived `*_table_name` readers.
- Permission errors in `MembersController` now return `403 Forbidden` instead of
  raising `StandardError` (which resulted in `500`).
- Creating an invite now requires the editor or admin role (matches the documented
  permission matrix). Previously any group member could create invites.

### Fixed

- Initial migration failed on a fresh database due to a duplicate index on
  `groupable_invites.code`. The index is now defined once, with a unique constraint.
- Engine models (`Groupable::Group`, `Groupable::Member`, `Groupable::Invite`) now
  respect configured class names (`user_class_name`, `group_class_name`, ...).
  Previously `Groupable::Member` hardcoded `class_name: "User"`.
- Controllers now resolve models through `Groupable.configuration` so that
  `group_class_name` / `member_class_name` / `invite_class_name` overrides apply to
  the API endpoints as well.
- Invalid or missing `role` parameter on member update now returns `400 Bad Request`
  instead of `500`.
- Validation errors (`ActiveRecord::RecordInvalid`) and missing parameters
  (`ActionController::ParameterMissing`) are now rendered as `422` / `400` instead of `500`.
- `config.enable_invites = false` now actually disables the invite and join endpoints (`404`).
- Joining via an invite that belongs to a soft-deleted group now returns `404`.
- Added `license` and corrected `homepage` / `source_code_uri` in the gemspec
  (previously pointed to the backstage repository).

### Changed

- `Groupable::Group` / `Groupable::Member` are now thin classes that include
  `GroupBehavior` / `MemberBehavior`, removing duplicated logic that had already
  started to drift.
- `GroupBehavior` now provides the `groupable_invites` association (aliased to
  `invites`) and an `active` scope.
- Association aliases (`members`, `users`, `groups`, `invites` and custom
  association names) are defined as real associations instead of `alias_method`,
  so reflection-based APIs (`joins`, `includes`, serializers) work with them.
- The shipped migration no longer adds foreign key constraints on
  `group_id` / `user_id`: the referenced tables depend on the configured classes
  (`group_class_name`, `user_class_name`), so fixed constraints to
  `groupable_groups` broke the documented existing-model setups. Add the
  constraints in your app if you use the engine's models exclusively (see README).
- `member_of_user` uses `find_by` instead of loading all members.
- `Groupable::Group` validates presence of `name`.

## 0.1.0

- Initial version.
