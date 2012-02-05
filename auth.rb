module Authentication
  protected
  def signed_in?
    !!current_user
  end

  def current_user
    @current_user ||= sign_in_from_session unless @current_user == false
  end

  def current_user=(new_user)
    session[:user_id] = new_user ? new_user.id : nil
    @current_user = new_user || false
  end

  def authorized?
    signed_in?
  end

  def authenticate
    authorized? || access_denied
  end

  def access_denied
    redirect '/'
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect (session[:return_to] || default)
    session[:return_to] = nil
  end

  def sign_in_from_session
    if session[:user_id]
      self.current_user = User.find_by_id(session[:user_id])
    end
  end

  def sign_in_from_basic_auth
    authenticate_with_http_basic do |email, password|
      use Rack::Auth::Basic, "Protected Area" do |email, password|
        self.current_user = User.authenticate(email, password)
      end
    end
  end

  def authenticate_with_login_form(email, password)
    self.current_user = User.authenticate(email, password)
 end

  def sign_out_keeping_session!
    puts 'setting session to nil'
    @current_user = false
    session[:user_id] = nil
    session[:flash] = nil
  end

  def sign_out_killing_session!
    sign_out_keeping_session!
    reset_session
  end
end

