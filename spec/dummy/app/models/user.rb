class User < ApplicationRecord
  include Groupable::UserGroupable
end
