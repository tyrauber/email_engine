module EmailEngine
  module Mailer
    def self.included(base)
      base.extend ClassMethods
      base.prepend InstanceMethods
      base.class_eval do
        attr_accessor :email_engine_options
        class_attribute :email_engine_options
        self.email_engine_options = {}
      end
    end

    module ClassMethods
      def track(options = {})
        self.email_engine_options = email_engine_options.merge(options)
      end
    end

    module InstanceMethods
      def track(options = {})
        self.email_engine_options = (email_engine_options || {}).merge(options)
      end

      def mail(headers = {}, &block)

        # this mimics what original method does
        return message if @_mail_was_called && headers.blank? && !block

        message = super
        EmailEngine::Processor.new(message, self).process
        message
      end
    end
  end
end
