module EmailEngine
  class Interceptor
    class << self
      def delivering_email(message)
        EmailEngine::Processor.new(message).deliver
      end
    end
  end
end
