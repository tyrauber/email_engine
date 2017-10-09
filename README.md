# EmailEngine

Send and track emails at scale with Rails and Redis

You get:

- A history of every email sent
- Track Sent, Open, Click, Unsubscribe, Success, Bounce and Complaint
- Easy UTM tagging

Works with any STMP provider but has built in Amazon SES callbacks (Success, Bounce and Complaint).

# Purpose

Send and track *hundreds of thousands of emails per hour*, with minimal resources.

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

## Authorization

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

The tracking of email headers, content and statistics are all handled through Redis.

Every email has a unique Message Token, which is applied to the email header as "EMAIL-ENGINE-ID".  Open, click and unsubscribe links use that Message Token to track usage, and stats are generated.

An admin provides the ability to monitor email performance.

### Users

EmailEngine tracks the user a message is sent to - not just the email address.  This gives you a full history of messages for each user, even if he or she changes addresses.

By default, EmailEngine tries `User.where(email: message.to.first).first` to find the user.

You can pass a specific user with:

```ruby
class UserMailer < ActionMailer::Base
  def welcome_email(user)
    # ...
    track user: user
    mail to: user.email
  end
end
```

### Opens

An invisible pixel is added right before the `</body>` tag in HTML emails.

If the recipient has images enabled in his or her email client, the pixel is loaded and the open time recorded.

Use `track open: false` to skip this.

### Clicks

A redirect is added to links to track clicks in HTML emails.

```
http://chartkick.com
```

becomes

```
http://you.io/ahoy/messages/rAnDoMtOkEn/click?url=http%3A%2F%2Fchartkick.com&signature=...
```

A signature is added to prevent [open redirects](https://www.owasp.org/index.php/Open_redirect).

Use `track click: false` to skip tracking, or skip specific links with:

```html
<a data-skip-click="true" href="...">Can't touch this</a>
```

### UTM Parameters

UTM parameters are added to links if they don’t already exist.

The defaults are:

- utm_medium - `email`
- utm_source - the mailer name like `user_mailer`
- utm_campaign - the mailer action like `welcome_email`

Use `track utm_params: false` to skip tagging, or skip specific links with:


```html
<a data-skip-utm-params="true" href="...">Break it down</a>
```

### Extra Attributes

Extra Attributes can be added to the email record.

```ruby
track extra: {campaign_id: 1}
```

## Customize

### Configuration

There are 4 places to set options. Here’s the order of precedence.

#### Action

``` ruby
class UserMailer < ActionMailer::Base
  def welcome_email(user)
    # ...
    track user: user
    mail to: user.email
  end
end
```

#### Mailer

```ruby
class UserMailer < ActionMailer::Base
  track utm_campaign: "boom"
end
```

#### Global

```ruby
EmailEngine.track open: false
```

#### Initializer

```ruby
EmailEngine.configure do |config|
  config.send = true
  config.open = true
  config.click = true
  config.unsubscribe = true
  config.unsubscribe_method = nil
  config.utm_params = true
  config.url_options = {}
  config.redis_url = "redis://localhost:6379/"
  config.store_email_content = true
  config.expire_email_content = 1.hour
end
```

## Reference

You can use a `Proc` for any option.

```ruby
track utm_campaign: proc{|message, mailer| mailer.action_name + Time.now.year }
```

Disable tracking for an email

```ruby
track message: false
```

Or specific actions

```ruby
track only: [:welcome_email]
track except: [:welcome_email]
```

Or by default

```ruby
EmailEngine.track message: false
```

Customize domain

```ruby
track url_options: {host: "mydomain.com"}
```

Use a different model

```ruby
EmailEngine.message_model = UserMessage
```


## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/tyrauber/email_engine/issues)
- Fix bugs and [submit pull requests](https://github.com/tyrauber/email_engine/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

## Special Thanks

This gem was inspired by, and evolved from, AhoyEmail written by Andrew Kane.
