ENV["RAILS_ENV"] ||= "test"

# Set database configuration path before loading environment
ENV["DATABASE_URL"] ||= "sqlite3:spec/dummy/db/test.sqlite3"

require File.expand_path("dummy/config/environment", __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"

# Load support files
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

# Setup database
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: File.expand_path("dummy/db/test.sqlite3", __dir__)
)

# Load schema
load File.expand_path("dummy/db/schema.rb", __dir__)

# Load dummy app
require File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
require File.expand_path("dummy/app/models/application_record.rb", __dir__)
require File.expand_path("dummy/app/models/user.rb", __dir__)

RSpec.configure do |config|
  config.fixture_path = nil
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Request helper
  config.include RequestSpecHelper, type: :request

  # Controller helper - include json helper for controller specs too
  config.include Module.new {
    def json
      JSON.parse(response.body)
    end
  }, type: :controller

  # For engine testing: set the app to use the dummy app
  config.before(:each, type: :request) do
    @app = Rails.application
  end
end
