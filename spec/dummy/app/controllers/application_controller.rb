class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # helper_method :email_engine_unsubscribe!
  #
  # def email_engine_unsubscribe!(hash={})
  #   Rails.logger.info ["email_engine_unsubscribe!", hash.inspect]
  # end
  #
  # before_filter  :email_engine_unsubscribe!
  
  include EmailEngine::EmailHelper
end
