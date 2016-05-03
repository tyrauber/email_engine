EmailEngine.configure do |config|
  config.send = true
  config.open = true
  config.click = true
  config.unsubscribe = true
  config.utm_params = true
  config.url_options = {}
  config.redis_url = "redis://localhost:6379/"
  config.store_email_content = true
  config.expire_email_content = 1.hour
end
