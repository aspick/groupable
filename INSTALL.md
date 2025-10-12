# Groupable Installation Guide

This guide explains how to integrate the Groupable Engine into an existing Rails application.

## Prerequisites

- Rails 7.2 or higher
- User model must exist
- Authentication must be implemented (current_user method available)

## Installation Steps

### 1. Add to Gemfile

```ruby
gem 'groupable', path: 'groupable'
```

### 2. Run bundle install

```bash
bundle install
```

### 3. Install migrations

```bash
rails groupable:install:migrations
rails db:migrate
```

This will create the following tables:
- `groupable_groups`
- `groupable_members`
- `groupable_invites`

### 4. Configure routing

Add the following to `config/routes.rb`:

```ruby
mount Groupable::Engine => "/groupable"
```

This will make the following endpoints available:
- `/groupable/groups`
- `/groupable/groups/:id/members`
- `/groupable/join`
etc.

### 5. Include UserGroupable in User model

`app/models/user.rb`:

```ruby
class User < ApplicationRecord
  include Groupable::UserGroupable

  # Other configurations...
end
```

### 6. Implement current_user in ApplicationController

Groupable controllers require the `current_user` method.

If you already have authentication, use it.

```ruby
class ApplicationController < ActionController::API
  # Existing authentication logic
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end
```

Alternatively, you can create a concern to share it.

### 7. Create configuration file (Optional)

You can skip this if the default configuration works for you.

`config/initializers/groupable.rb`:

```ruby
Groupable.configure do |config|
  # User model class name (default: 'User')
  config.user_class_name = 'User'

  # Model class configuration (choose existing models or Engine models)
  config.group_class_name = 'Groupable::Group'   # default
  config.member_class_name = 'Groupable::Member' # default
  config.invite_class_name = 'Groupable::Invite' # default

  # Enable invite feature (default: true)
  config.enable_invites = true

  # Invite code expiration (days) (default: 30)
  config.invite_expiry_days = 30

  # Default role (default: :member)
  config.default_role = :member

  # Available roles definition (default: [:member, :editor, :admin])
  config.roles = [:member, :editor, :admin]
end
```

**When using existing models:**

If you have an existing `Group` model, you can use it instead of the Engine's model:

```ruby
Groupable.configure do |config|
  config.group_class_name = 'Group'  # Use existing Group model
  # member_class_name is not specified, so Groupable::Member will be used
end

# app/models/group.rb
class Group < ApplicationRecord
  include Groupable::GroupBehavior

  # Existing associations and logic remain as is
  has_many :recordings
end
```

This allows:
- ✅ Use existing `groups` table as is
- ✅ Members are managed in new `groupable_members` table
- ✅ No data migration needed

### 8. Restart the server

```bash
rails server
```

## Verification

### Test API endpoints

```bash
# Get list of groups
curl -X GET http://localhost:3000/groupable/groups \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create a group
curl -X POST http://localhost:3000/groupable/groups \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"item": {"name": "Test Group"}}'
```

### Test in Rails Console

```ruby
# Get a user
user = User.first

# Create a group
group = Groupable::Group.create_new_group!("My Group", user)

# Check group list
user.groups
# or
user.groupable_groups

# Check members
group.members

# Create invite code
invite = group.invites.create!
puts invite.code
```

## Migration from Existing Group Functionality

If you have an existing `Group` model, you can migrate with the following steps:

### 1. Create data migration script

```ruby
# lib/tasks/migrate_to_groupable.rake
namespace :groupable do
  desc "Migrate existing groups to Groupable"
  task migrate: :environment do
    Group.find_each do |old_group|
      new_group = Groupable::Group.new(
        name: old_group.name,
        active: true,
        created_at: old_group.created_at,
        updated_at: old_group.updated_at
      )
      new_group.save!(validate: false)

      # Migrate members
      old_group.members.each do |old_member|
        Groupable::Member.create!(
          group: new_group,
          user: old_member.user,
          role: old_member.role,
          created_at: old_member.created_at
        )
      end
    end
  end
end
```

### 2. Run migration

```bash
rails groupable:migrate
```

### 3. Update existing code

```ruby
# Before
@groups = current_user.groups

# After
@groups = current_user.groupable_groups
```

## Troubleshooting

### Q: Getting error that `current_user` is not found

A: Define the `current_user` method in ApplicationController or Groupable::ApplicationController.

### Q: Tables are not created

A: Verify that migrations have been executed correctly:

```bash
rails db:migrate:status | grep groupable
```

### Q: Routing doesn't work

A: Verify that `mount Groupable::Engine => "/groupable"` is correctly configured in `config/routes.rb`.

```bash
rails routes | grep groupable
```

## Next Steps

- Check [README.md](README.md) for API usage
- Consider model extensions or callbacks if customization is needed
- Verify proper authentication and authorization implementation for production environment
