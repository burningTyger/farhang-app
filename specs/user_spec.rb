require "#{File.dirname(__FILE__)}/spec_helper"
include SpecHelper

describe User do
  describe 'routes' do
    before do
      @u = FactoryGirl.create :user
      post '/user/login', :email => @u.email, :password => 'secret'
    end

    it 'has a form to create a new User resource' do
      get '/user/new'
      last_response.body.must_include "/user"
    end

    it "can create a new User resource" do
      post '/user', u = FactoryGirl.attributes_for(:user)
      last_response.location.must_equal 'http://example.org/'
      u = User.find_by_email(u[:email])
      u.must_be_kind_of User
    end

    it "can show a user page" do
      get "/user/#{@u.id}"
      last_response.body.must_include @u.email
    end

    it "won't create an empty User resource" do
      post '/user'
      last_response.status.must_equal 400
    end

    it "can delete own User resource" do
      delete "/user/#{@u.id}"
      User.find(@u.id).must_be_nil
    end

    it "won't delete an unknown User resource" do
      count = User.count
      delete "/user/4321"
      User.count.must_equal count
    end

    it "can modify a User resource" do
      put "/user/#{@u.id}", :email => "mine@example.org"
      User.find(@u.id).email.must_equal "mine@example.org"
    end

    it "wont modify an unknown User resource" do
      put "/user/1234", :name => "Nelly"
      User.find("1234").must_be_nil
    end

    it "will let a user login with his credentials" do
      signed_in?.must_equal true
    end

    it "will create a user with only user role" do
      u = FactoryGirl.create :user
      u.roles.must_equal Set.new([:user])
    end

    it "will not let other users edit users" do
      u = FactoryGirl.create :user
      delete "/user/#{u.id}"
      User.find(u.id).must_equal u
    end
  end

  describe "root user management" do
    before do
      @ua = FactoryGirl.create :user, :roles => [:root, :user]
      post '/user/login', :email => @ua.email, :password => 'secret'
    end

    it "lets the root see the users page" do
      get "/users"
      last_response.status.must_equal 200
    end

    it "lets root change the user roles" do
      u = FactoryGirl.create :user
      patch "/user/#{u.id}/roles", :roles => "admin"
      follow_redirect!
      last_response.status.must_equal 200
      u.reload
      u.roles.must_equal [:user, :admin].to_set
    end
  end

  describe 'model' do
    it "validates presence of email" do
      proc {FactoryGirl.create :user, :email => ""}.must_raise(MongoMapper::DocumentNotValid)
    end

    it "validates length of email" do
      proc {FactoryGirl.create :user, :email => "a@a"}.must_raise(MongoMapper::DocumentNotValid)
      u = FactoryGirl.create :user, :email => "a@ac.co"
      u.save!.must_equal true
    end

    it "always stores email as lower case" do
      user = User.new
      user.email = 'F@FOOBAR.COM'
      user.email.must_equal 'f@foobar.com'
    end

    it "is able to set user's reset password code" do
      user = FactoryGirl.create :user
      user.reset_password_code.must_be_nil
      user.reset_password_code_until.must_be_nil
      user.set_password_code!
      user.reset_password_code.wont_be_nil
      user.reset_password_code_until.wont_be_nil
    end
  end

  describe "Authentication" do
    it 'works with existing email and correct password' do
      user = FactoryGirl.create :user
      User.authenticate(user.email, 'secret').must_equal user
    end

    it 'works with existing email (case insensitive) and password' do
      user = FactoryGirl.create :user
      User.authenticate(user.email.upcase, 'secret').must_equal user
    end

    it 'does not work with existing email and incorrect password' do
      User.authenticate('john@doe.com', 'foobar').must_be_nil
    end

    it 'does not work with non-existant email' do
      User.authenticate('foo@bar.com', 'foobar').must_be_nil
    end
  end

  describe "password" do
    it 'password is required if crypted password is blank' do
      proc {User.new.save!}.must_raise(MongoMapper::DocumentNotValid)
    end

    it 'password is not required if crypted password is present' do
      user = User.new
      user.email = "me@mo.co"
      user.crypted_password = BCrypt::Password.create('foobar')
      user.save!.must_equal true
    end

    it "validates the length of password" do
      proc {FactoryGirl.create :user, :password => "1234"}.must_raise(MongoMapper::DocumentNotValid)
      u = FactoryGirl.create :user, :password => "123456", :password_confirmation => "123456"
      u.save!.must_equal true
    end
  end

  after do
    User.delete_all
  end
end

