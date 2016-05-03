EmailEngine.configure do |config|
  config.redis_url = "redis://localhost:6379/"
  config.store_email_content = true
  config.expire_email_content = 1.hour
end
