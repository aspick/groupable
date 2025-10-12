# Groupable

Groupable is a Rails Engine that provides flexible group and membership management with role-based permissions and invite functionality.

## Features

- **Group Management**: Create, update, and manage groups
- **Role-Based Permissions**: Support for multiple roles (member, editor, admin)
- **Invite System**: Generate invite codes for adding members to groups
- **Flexible Configuration**: Customize roles, expiry periods, and more
- **API-Ready**: JSON API endpoints for all operations

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'groupable', path: 'groupable'
```

And then execute:

```bash
$ bundle install
```

## Setup

### 1. Run migrations

```bash
$ rails groupable:install:migrations
$ rails db:migrate
```

### 2. Mount the engine

Add to your `config/routes.rb`:

```ruby
mount Groupable::Engine => "/groupable"
```

### 3. Include UserGroupable in your User model

```ruby
class User < ApplicationRecord
  include Groupable::UserGroupable
end
```

### 4. Configure (Optional)

Create an initializer at `config/initializers/groupable.rb`:

```ruby
Groupable.configure do |config|
  # User model configuration
  config.user_class_name = 'User'

  # Model class configuration (use existing models or Engine models)
  config.group_class_name = 'Groupable::Group'   # Default
  config.member_class_name = 'Groupable::Member' # Default
  config.invite_class_name = 'Groupable::Invite' # Default

  # Feature flags
  config.enable_invites = true
  config.invite_expiry_days = 30

  # Role configuration
  config.default_role = :member
  config.roles = [:member, :editor, :admin]
end
```

**Note:** Table names are automatically derived from the class names. For example, if you set `config.group_class_name = 'Group'`, the engine will use `Group.table_name` (typically `'groups'`).

### 5. Implement current_user in your controllers

The engine expects a `current_user` method to be available. You can implement this in your `ApplicationController`:

```ruby
class ApplicationController < ActionController::API
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
end
```

Or if using a concern, ensure Groupable controllers inherit from it.

## API Endpoints

### Groups

- `GET /groupable/groups` - List all groups for current user
- `GET /groupable/groups/:id` - Show group details
- `POST /groupable/groups` - Create a new group
- `PUT /groupable/groups/:id` - Update group
- `DELETE /groupable/groups/:id` - Soft delete group (sets active to false)

### Members

- `GET /groupable/groups/:group_id/members` - List group members
- `GET /groupable/groups/:group_id/members/:id` - Show member details
- `PUT /groupable/groups/:group_id/members/:id` - Update member role
- `DELETE /groupable/groups/:group_id/members/:id` - Remove member from group

### Invites

- `POST /groupable/groups/:group_id/invites` - Create invite code
- `GET /groupable/join?code=xxx` - Preview group from invite code
- `POST /groupable/join` - Join group using invite code

## Usage Examples

### Creating a Group

```ruby
# Via API
POST /groupable/groups
{
  "item": {
    "name": "My Group"
  }
}

# Or in code
group = Groupable::Group.create_new_group!("My Group", current_user)
```

### Adding Members via Invite

```ruby
# 1. Create an invite
invite = group.invites.create!
# => Returns invite with code

# 2. Share the code with users

# 3. Users join via the code
POST /groupable/join
{
  "code": "abc123"
}
```

### Checking Permissions

```ruby
# Get user's member record
member = group.member_of_user(user)

# Check role
member.admin?    # => true/false
member.editor?   # => true/false
member.member?   # => true/false

# Get all groups for a user
user.groups
# or
user.groupable_groups
```

### Role Management

```ruby
# Update member role (must be editor or admin)
PUT /groupable/groups/:group_id/members/:user_id
{
  "item": {
    "role": "editor"
  }
}
```

## Roles and Permissions

The engine supports three default roles:

- **member**: Basic group member (can view)
- **editor**: Can edit group and manage members
- **admin**: Full control, can delete group and promote/demote members

### Permission Matrix

| Action | Member | Editor | Admin |
|--------|--------|--------|-------|
| View group | ✓ | ✓ | ✓ |
| Edit group | ✗ | ✓ | ✓ |
| Add members via invite | ✗ | ✓ | ✓ |
| Remove members | ✗ | ✓ | ✓ |
| Change member roles | ✗ | ✓ (except admin) | ✓ |
| Delete group | ✗ | ✗ | ✓ |

## Using Existing Models

Groupable allows you to use your existing Group/Member models instead of the Engine's models. This is useful when migrating an existing application or when you need to maintain existing data structures.

### Example 1: Using Existing Group Model Only

If you already have a `Group` model and want to add Groupable functionality:

```ruby
# config/initializers/groupable.rb
Groupable.configure do |config|
  config.group_class_name = 'Group'
  # Member and Invite will use Engine's models (Groupable::Member, Groupable::Invite)
end

# app/models/group.rb
class Group < ApplicationRecord
  include Groupable::GroupBehavior

  # Your existing associations and logic
  has_many :recordings
  has_many :custom_resources
end
```

With this setup:
- ✅ Uses existing `groups` table
- ✅ Members are stored in `groupable_members` table
- ✅ Groupable methods (`joined?`, `join!`, etc.) are available on Group
- ✅ Existing business logic is preserved

### Example 2: Using All Existing Models

If you have both Group and Member models:

```ruby
# config/initializers/groupable.rb
Groupable.configure do |config|
  config.group_class_name = 'Group'
  config.member_class_name = 'Member'
end

# app/models/group.rb
class Group < ApplicationRecord
  include Groupable::GroupBehavior
  # ... existing code
end

# app/models/member.rb
class Member < ApplicationRecord
  include Groupable::MemberBehavior
  # ... existing code
end
```

With this setup:
- ✅ Uses existing `groups` and `members` tables
- ✅ All Groupable functionality added via concerns
- ✅ No data migration needed

### Example 3: Mixed Approach

You can mix and match as needed:

```ruby
Groupable.configure do |config|
  config.group_class_name = 'Group'              # Use existing Group
  config.member_class_name = 'Groupable::Member' # Use Engine's Member
  config.invite_class_name = 'MyInvite'          # Use custom Invite
end
```

## Customization

### Custom Roles

You can define custom roles in the configuration:

```ruby
Groupable.configure do |config|
  config.roles = [:viewer, :contributor, :moderator, :owner]
  config.default_role = :viewer
end
```

### Extending Models

You can extend the engine models in your application:

```ruby
# app/models/groupable/group_extension.rb
module Groupable
  Group.class_eval do
    has_many :custom_resources

    def custom_method
      # Your custom logic
    end
  end
end
```

### Custom Group Creation Logic

Use the block syntax to add custom logic during group creation:

```ruby
Groupable::Group.create_new_group!("My Group", user) do |group, options|
  # Add custom logic here
  group.create_custom_setting!(options[:custom_data])
end
```

## Database Schema

The engine creates the following tables:

- `groupable_groups` - Group information
- `groupable_members` - Join table between users and groups with roles
- `groupable_invites` - Invite codes for joining groups

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
