module EmailEngine
  class Engine < ::Rails::Engine
    isolate_namespace EmailEngine

    initializer "email_engine" do |app|
      secrets = app.respond_to?(:secrets) ? app.secrets : app.config
      EmailEngine.secret_token ||= secrets.respond_to?(:secret_key_base) ? secrets.secret_key_base : secrets.secret_token
    end
    #
    # initializer "email_engine.assets.precompile" do |app|
    #   app.config.assets.precompile += %w(email_engine.css email_engine.js)
    # end
    config.to_prepare do
      Rails.application.config.assets.precompile += %w(email_engine/email_engine.css email_engine/email_engine.js)
    end
  end
end
