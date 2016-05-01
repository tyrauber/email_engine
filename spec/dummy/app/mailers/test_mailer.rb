class TestMailer < ActionMailer::Base

  if defined?(Sidekiq)
    Sidekiq::Extensions::DelayedMailer.sidekiq_options :queue => 'mailers'
  end
 
  default from: '"Test" <test@example.com>'
 
  def notify(to_email, links=50, subject=nil, body=nil)
    subject ||= Faker::Company.catch_phrase
    body ||= "<html><head></head><body><div style='max-width:600px;margin: 0px auto'><h1>#{Faker::Hipster.sentence}</h1>#{Faker::Hipster.paragraph}<br/></br/>#{(0..links.to_i).to_a.map{|i| "<a href='#{Faker::Internet.url}'>LINK #{i}</a>"}.join("")}<a href='http://example.com/users/unsubscribe'>UNSUBSCRIBE</a></div></body></html>"
    mail({ to: to_email, subject: subject, body: body.dup, content_type: "text/html" })
  end
end