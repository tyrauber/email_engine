EmailEngine.configure do |config|
  config.redis_url = "redis://localhost:6379/1"
  config.store_email_headers = true
  config.expire_email_headers = 1.day
  config.store_email_content = true
  config.expire_email_content = 1.day
  config.unsubscribe_method = 'email_engine_subscribe!'
end
