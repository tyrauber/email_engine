require "rails/generators"

module EmailEngine
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      def copy_initializer
        copy_file 'initializer.rb', 'config/initializers/email_engine.rb'
        copy_file 'helper.rb', 'app/helpers/email_engine/email_helper.rb'
      end
    end
  end
end
