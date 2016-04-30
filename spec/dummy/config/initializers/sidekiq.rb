Sidekiq.configure_server do |config|
  config.on(:startup) do
    database_url = ENV['DATABASE_URL']
    if database_url
      ENV['DATABASE_URL'] = "#{database_url}?pool=#{ENV['SIDEKIQ_WEB_CONCURRENCY']||5}"
      ActiveRecord::Base.establish_connection
    end
  end
end
Sidekiq.default_worker_options = {
   'unique_args' => proc do |args|
     [args.first.except('job_id')]
   end
}
SidekiqUniqueJobs.config.unique_args_enabled = true
