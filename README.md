# EmailEngine

:postbox: Send and track emails at scale with Rails and Redis

You get:

- A history of emails sent to each user
- Open and click tracking
- Easy UTM tagging

Works with any STMP provider but has built in Amazon SES callbacks.

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'email_engine'
```

Generate and modify the initializer:

```ruby
rails generate email_engine:install
```

## How It Works


The tracking of email headers, content, open and click counts are all handled in Redis.

Every email has a unique Message Token, which is applied to the email header as "MESSAGE-TOKEN".  Open, click and unsubscribe links use that Message Token to reference the original email.

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/tyrauber/email_engine/issues)
- Fix bugs and [submit pull requests](https://github.com/tyrauber/email_engine/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## Special Thanks

This gem was inspired by, and evolved from, AhoyEmail written by Andrew Kane.