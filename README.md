# EmailEngine

:postbox: Send and track emails at scale with Rails and Redis

You get:

- A history of every email sent
- Track Open, Click, Unsubscribe, Bounce and Complaint
- Easy UTM tagging

Works with any STMP provider but has built in Amazon SES callbacks.

# In Development. Subject to Change

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'email_engine'
```

Generate and modify the initializer:

```ruby
rails generate email_engine:install
```

## Routes

By default, EmailEngine will mount at root with /emails as the user facing resource and /admin/emails as the admin resource.  You can change the route by manually mounting the engine.

```ruby
  mount EmailEngine::Engine => "/messages", as: 'email_engine'
```

If you use RailsEngine, ActiveAdmin or any other /admin namespaced engine, you'll need to mount EmailEngine first, otherwise the other engine might override the EmailEngine admin routes.

## Security

EmailEngine is configured to leverage the CanCan Authorization gem and the existing ability file.  The following ability example would grant basic access to all users and restrict access to the EmailEngine admin to only users where user.admin? is true.

```ruby
  def initialize(user)
    user ||= User.new
    can [:open, :click, :unsubscribe, :bounce, :complaint], EmailEngine::Email
    if user.admin?
      can :manage, EmailEngine::Email
    end
  end
```

## How It Works

The tracking of email headers, content, open and click counts are all handled in Redis.

Every email has a unique Message Token, which is applied to the email header as "EMAIL-ENGINE-ID".  Open, click and unsubscribe links use that Message Token to track usage, and stats are generated.

An admin provides the ability to monitor email performance.

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/tyrauber/email_engine/issues)
- Fix bugs and [submit pull requests](https://github.com/tyrauber/email_engine/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## Special Thanks

This gem was inspired by, and evolved from, AhoyEmail written by Andrew Kane.