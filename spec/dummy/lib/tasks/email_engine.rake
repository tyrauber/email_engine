namespace :email_engine do 
  task :performance, [:email_count,:link_count] => :environment  do |t, args|
    args.with_default(email_count: 1000, link_count: 50)
    p '# SES Engine Performance Testing'
    p 'Measuring the performance of Open and Click Tracking.'
    p 'rake email_engine:performance[email_count,link_count]'
    p 'Default email_count is 1000, and link_count is 50.'

    Benchmark.ips do |x|
      x.report('tracking open and click (deliver_now)') do
        TestWorker.new.perform(args[:email_count], args[:link_count], false, true, true)
      end

      x.report('tracking open, not click (deliver_now)') do
        TestWorker.new.perform(args[:email_count], args[:link_count], false, true, false)
      end
      
      x.report('tracking click, not open (deliver_now)') do
        TestWorker.new.perform(args[:email_count], args[:link_count], false, false, false)
      end

      x.report('tracking neither open or click (deliver_now)') do
        TestWorker.new.perform(args[:email_count], args[:link_count], false, false, false)
      end

      p x.compare!
    end
  end
end