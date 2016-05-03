module EmailEngine
  class Engine < ::Rails::Engine
    isolate_namespace EmailEngine

    initializer "email_engine" do |app|
      secrets = app.respond_to?(:secrets) ? app.secrets : app.config
      EmailEngine.secret_token ||= secrets.respond_to?(:secret_key_base) ? secrets.secret_key_base : secrets.secret_token
    end
  end
end
