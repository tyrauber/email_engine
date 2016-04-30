module EmailEngine
  module EmailHelper
    def self.unsubscribe_method!(hash={})
      Rails.logger.info "Configure EmailEngine::EmailHelper.unsubscribe_method! in /app/helpers/email_engine/email_helper.rb"
    end

    def self.bounce_method!(hash={})
      Rails.logger.info "Configure EmailEngine::EmailHelper.bounce_method! in /app/helpers/email_engine/email_helper.rb"
    end

    def self.complaint_method!(hash={})
      Rails.logger.info "Configure EmailEngine::EmailHelper.complaint_method! in /app/helpers/email_engine/email_helper.rb"
    end
  end
end