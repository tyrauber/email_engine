module EmailEngine
  class Interceptor
    class << self
      def delivering_email(message)
        EmailEngine::Processor.new(message).track_send
      end
    end
  end
end
