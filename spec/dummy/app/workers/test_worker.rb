class TestWorker

  def perform(limit=1000, links=50, delay=false, open=true, click=true)
    `rm -rf #{Rails.root}/tmp/emails`
    TestMailer.class_eval do
      track open: !!(open)
      track click: !!(click)
    end
    emails ||= (1..limit.to_i).to_a.map{|i|  Faker::Internet.email.split("@").join("+#{i}@") }

    emails.each_with_index do |email, index|
      if !!(delay)
        email = TestMailer.notify(email, links).deliver_later!
      else
        email = TestMailer.notify(email, links).deliver_now!
      end
    end
  end
end
