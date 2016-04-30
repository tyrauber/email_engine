module EmailEngine
  module EmailHelper

    def self.unsubscribe_method!(hash={})
      Rails.logger.info "EmailEngine::EmailHelper.unsubscribe_method! not implemented."
    end

    def self.bounce_method!(hash={})
      Rails.logger.info "EmailEngine::EmailHelper.bounce_method! not implemented."
    end

    def self.complaint_method!(hash={})
      Rails.logger.info "EmailEngine::EmailHelper.complaint_method! not implemented."
    end
  end
end