require "email_engine/version"
require "action_mailer"
require "rails"
require "addressable/uri"
require "openssl"
require "safely_block"
require "redis"
require "email_engine/utilities"
require "email_engine/processor"
require "email_engine/interceptor"
require "email_engine/mailer"
require "email_engine/engine"

module EmailEngine
  mattr_accessor :secret_token, :options

  self.options = {
    redis_url: "redis://localhost:6379/",
    send: true,
    open: true,
    click: true,
    unsubscribe: true,
    unsubscribe_method: nil,
    utm_params: true,
    utm_source: nil,
    utm_medium: "email",
    utm_term: nil,
    utm_content: nil,
    utm_campaign: nil,
    mailer: nil,
    url_options: {}
  }

  def self.track(options)
    self.options = self.options.merge(options)
  end

  def self.redis
    uri ||= URI.parse(options[:redis_url])
    @redis ||= Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :redis_url, :store_email_headers, :store_email_content, :expire_email_headers, :expire_email_content, :unsubscribe_method

    def initialize
      @redis_url = "redis://localhost:6379/"
      @store_email_headers = true
      @store_email_content = true
      @expire_email_headers = false
      @expire_email_content = false
    end
  end
end


ActionMailer::Base.send :include, EmailEngine::Mailer
ActionMailer::Base.register_interceptor EmailEngine::Interceptor
