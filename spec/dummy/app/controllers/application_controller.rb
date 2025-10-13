class ApplicationController < ActionController::API
  def current_user
    return @current_user if defined?(@current_user)

    # For testing: allow setting user via header
    # Rails converts X-Test-User-Id to HTTP_X_TEST_USER_ID
    if Rails.env.test?
      user_id = request.headers['HTTP_X_TEST_USER_ID'] || request.headers['X-Test-User-Id']
      @current_user = User.find_by(id: user_id) if user_id.present?
    else
      @current_user = User.first
    end

    @current_user
  end
end
