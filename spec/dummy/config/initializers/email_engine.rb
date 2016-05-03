EmailEngine.configure do |config|
  config.send = true
  config.open = true
  config.click = true
  config.unsubscribe = true
  config.unsubscribe_method = nil
  config.utm_params = true
  config.utm_source = nil
  config.utm_medium = "email"
  config.utm_term = nil
  config.utm_content = nil
  config.utm_campaign = nil
  config.mailer = nil
  config.url_options = {}
  config.redis_url = "redis://localhost:6379/"
  config.store_email_content = true
  config.expire_email_content = 1.hour
end
