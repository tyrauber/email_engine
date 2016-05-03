require_relative "test_helper"

class UserMailer < ActionMailer::Base
  default from: "from@example.com"
  after_action :prevent_delivery_to_guests, only: [:welcome2] if Rails.version >= "4.0.0"

  def welcome
    mail to: "test@example.org", subject: "Hello", body: "World"
  end

  def welcome2
    mail to: "test@example.org", subject: "Hello", body: "World"
  end

  def welcome3
    track message: false
    mail to: "test@example.org", subject: "Hello", body: "World"
  end

  private

  def prevent_delivery_to_guests
    mail.perform_deliveries = false
  end
end

class MailerTest < Minitest::Test
  def setup
    EmailEngine.redis.flushall
  end

  def test_basic
    assert_message :welcome
  end

  def test_prevent_delivery
    message = UserMailer.send(:welcome2)
    message.respond_to?(:deliver_now) ? message.deliver_now! : message.deliver
    if Rails.version >= "4.0.0"
      assert_equal false, EmailEngine.redis.hexists('email_engine:email', message['EMAIL-ENGINE-ID'])
    end
  end

  def test_no_message
    message = UserMailer.welcome3
    assert_equal false, EmailEngine.redis.hexists('email_engine:email', message['EMAIL-ENGINE-ID'])
  end

  def assert_message(method)
    message = UserMailer.send(method)
    message.respond_to?(:deliver_now) ? message.deliver_now! : message.deliver
    assert_equal true, EmailEngine.redis.hexists('email_engine:email', message['EMAIL-ENGINE-ID'])
    email =  EmailEngine::Email.find(message['EMAIL-ENGINE-ID'])
    assert_equal "test@example.org", email.to
    assert_equal "UserMailer##{method}", email.mailer
    assert_equal "Hello", email.subject
    assert_equal "user_mailer", email.utm_source
    assert_equal "email", email.utm_medium
    assert_equal method.to_s, email.utm_campaign
  end
end
