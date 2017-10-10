require "email_engine/version"
require "action_mailer"
require "rails"
require "addressable/uri"
require "openssl"
require "safely_block"
require "redis"
require "email_engine/processor"
require "email_engine/interceptor"
require "email_engine/mailer"
require "email_engine/engine"

module EmailEngine

  mattr_accessor :secret_token, :options
  
  def self.options
    self.configuration.to_h
  end

  def self.track(options)
    self.options = self.options.merge(options)
  end
  
  def self.redis
    self.configuration.redis
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure(&block)
    self.configuration ||= Configuration.new
    yield(configuration)
    self.configuration.redis_url ||= "redis://localhost:6379/"
    redis_uri ||= URI.parse(self.configuration.redis_url)
    self.configuration.redis ||= Redis.new(:host => redis_uri.host, :port => redis_uri.port, :password => redis_uri.password)
  end

  class Configuration
    attr_accessor :send, :open, :click, :unsubscribe, :unsubscribe_method, :url_options,
    :utm_params, :utm_source, :utm_medium, :utm_term, :utm_content, :utm_campaign, :mailer, 
    :redis_url, :redis, :store_email_content, :expire_email_content, :unsubscribe_method

    def initialize
      @send = true
      @open = true
      @click = true
      @unsubscribe = true
      @unsubscribe_method = nil
      @utm_params = true
      @utm_source = proc { |message, mailer| mailer.mailer_name }
      @utm_medium =  "email"
      @utm_term = nil
      @utm_content = nil
      @utm_campaign = proc { |message, mailer| mailer.action_name }
      @user = proc { |message, mailer| (message.to.size == 1 ? User.where(email: message.to.first).first : nil) rescue nil }
      @mailer = proc { |message, mailer| "#{mailer.class.name}##{mailer.action_name}" }
      @url_options = {}
      @store_email_content = true
      @expire_email_content = false
    end

    def to_h(hash={})
      instance_variables.each {|var| hash[var.to_s.delete("@").to_sym] = instance_variable_get(var) }
      hash
    end
  end

  ActionMailer::Base.send :include, EmailEngine::Mailer
  ActionMailer::Base.register_interceptor EmailEngine::Interceptor
end

