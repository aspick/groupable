module RequestSpecHelper
  def json
    JSON.parse(response.body)
  end

  def set_current_user(user)
    @test_user = user
  end

  # Override HTTP methods to include user ID header
  def get(path, **args)
    add_test_user_header(args)
    super(path, **args)
  end

  def post(path, **args)
    add_test_user_header(args)
    super(path, **args)
  end

  def put(path, **args)
    add_test_user_header(args)
    super(path, **args)
  end

  def patch(path, **args)
    add_test_user_header(args)
    super(path, **args)
  end

  def delete(path, **args)
    add_test_user_header(args)
    super(path, **args)
  end

  private

  def add_test_user_header(args)
    if @test_user
      args[:headers] ||= {}
      args[:headers]['X-Test-User-Id'] = @test_user.id.to_s
    end
  end
end
