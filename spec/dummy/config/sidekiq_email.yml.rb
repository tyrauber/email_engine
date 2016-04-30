---
:verbose: false
:concurrency: <%= ENV['SIDEKIQ_EMAIL_CONCURRENCY']||40 %>
:queues:
  - [mailers, 1]