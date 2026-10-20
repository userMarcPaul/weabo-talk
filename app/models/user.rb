class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Associations
  has_one :profile, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Follows (one-way): people this user follows, and people who follow this user
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  # Callbacks
  after_create :create_profile

  # Email confirmation is off unless REQUIRE_EMAIL_CONFIRMATION=true (e.g. while the app
  # can't send email). When off, new users can sign in right away and no email is sent.
  def self.email_confirmation_required?
    ENV["REQUIRE_EMAIL_CONFIRMATION"] == "true"
  end

  def following?(user)
    active_follows.exists?(followed: user)
  end

  # Use custom mailer for sending emails
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  protected

  # Devise checks this before generating a token, sending the confirmation email and
  # signing in, so it switches all three
  def confirmation_required?
    self.class.email_confirmation_required? && super
  end

  # Email changes apply right away instead of waiting for a confirmation email
  def postpone_email_change?
    self.class.email_confirmation_required? && super
  end

  private

  def devise_mailer
    Users::UserMailer
  end

  def create_profile
    Profile.create!(user: self, username: generate_username)
  end

  # Build a username from the email (before @) that passes Profile validations:
  # letters, numbers and underscores only, 3-30 characters, unique
  def generate_username
    # Leave room for a 4-digit suffix within the 30 character limit
    base = email.split("@").first.downcase.gsub(/[^a-z0-9_]+/, "_")[0, 26]
    base = "user_#{base}" if base.length < 3

    username = base
    # Ensure uniqueness by appending random suffix if needed
    username = "#{base}#{rand(1000..9999)}" while Profile.exists?(username: username)
    username
  end

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, on: :create
  validates :password_confirmation, presence: true, on: :create
end
