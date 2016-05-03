module EmailEngine
  class Processor
    attr_reader :message, :mailer

    UTM_PARAMETERS = %w(utm_source utm_medium utm_term utm_content utm_campaign)

    def initialize(message, mailer = nil)
      @message = message
      @mailer = mailer
    end

    def process
      safely do
        message['EMAIL-ENGINE-ID'] = token.dup
        message['EMAIL-ENGINE-HEADERS'] = mailer.email_engine_options.merge({
          utm_medium: 'email',
          utm_source: mailer.class.name.gsub!(/(.)([A-Z])/,'\1_\2').downcase,
          utm_campaign: mailer.action_name,
          mailer: [mailer.class.name, mailer.action_name].join("#"),
          utm_term: message.subject.tr('^A-Za-z0-9', '')[0,24],
          utm_content: message['EMAIL-ENGINE-ID']
        }).to_json
        message['EMAIL-ENGINE-HEADERS']
      end
    end

    def deliver
      safely do
        if (message["EMAIL-ENGINE-ID"]) && message.perform_deliveries
          track_unsubscribe if options[:unsubscribe]
          track_open if options[:open]
          track_links if options[:utm_params] || options[:click]
          track_send if options[:send]
          message['EMAIL-ENGINE-HEADERS'] = nil
        end
      end
    end

    protected

    def default_url
      @opt ||= EmailEngine::Engine.routes.url_helpers.url_for((ActionMailer::Base.default_url_options || {}).merge(controller: "email_engine/emails", action: "click", id: "$ID$"))
    end

    def options
      @options ||= begin
        mailer_options = JSON.parse(message['EMAIL-ENGINE-HEADERS'].value)
        options = EmailEngine.options.merge!(mailer_options)
        # if mailer_options
        #   options = options.except(:only, :except).merge(mailer_options)
        # end
        # options.each do |k, v|
        #   if v.respond_to?(:call)
        #     options[k] = v.call(message, mailer)
        #   end
        # end
        options
      end
    end

    def token
      #SecureRandom.urlsafe_base64(32).gsub(/[\-_]/, "").first(32)
      #message.__id__
      #@token ||= "#{DateTime.now.strftime('%Q')}.#{'%04d' % rand(4** 4)}"
      @token ||= "#{DateTime.now.strftime('%Q')}"
    end

    def message_hash
      @message_hash ||= JSON.parse(message['EMAIL-ENGINE-HEADERS'].value).merge!({
        id: message["EMAIL-ENGINE-ID"].value,
        to: message.to,
        subject: message.subject,
        sent_at: now.to_i
      })
    end

    def track_send
      safely do
        if (message["EMAIL-ENGINE-ID"]) && message.perform_deliveries
            @email = Email.new(message)
            @email.save!

            #@email.increment!(:sent)
            # EmailEngine.redis.multi do
            #
            #   # Email Headers
            #   EmailEngine.redis.zadd('email_engine:emails', message["EMAIL-ENGINE-ID"], message_hash.to_json)
            #
            #   # Email Content
            #   if !!(EmailEngine.configuration.store_email_content)
            #     EmailEngine.redis.setex("email_engine:emails:#{message["EMAIL-ENGINE-ID"]}:content", EmailEngine.configuration.expire_email_content.to_i, (message.html_part || message).body)
            #   end
            #
            #   # Email Sent Stats
            #   date = DateTime.now.strftime("%Y:%m:%d:%H:%M").split(":")
            #   headers = JSON.parse(message['EMAIL-ENGINE-HEADERS'].value).values
            #   p "email_engine:stats:#{date.join(":")}"
            #   date.length.times.each do |i|
            #     headers.each do |x|
            #       p ["email_engine:stats:#{date[0,i+1].join(":")}", "#{headers.map { |o| o==x ? "*" : o}.join(":")}:sent"]
            #       EmailEngine.redis.hincrby("email_engine:stats:#{date[0,i+1].join(":")}", "#{headers.map { |o| o==x ? "*" : o}.join(":")}:sent", 1)
            #     end
            #   end
            # end
        end
      end
    end

    def track_open
      if html_part?
        raw_source = (message.html_part || message).body.raw_source
        regex = /<\/body>/i
        id = message["EMAIL-ENGINE-ID"].value
        url = default_url.gsub("$ID$", id).gsub("/click", "/open.gif")
        pixel = ActionController::Base.helpers.image_tag(url, size: "1x1", alt: nil)
        if raw_source.match(regex)
          raw_source.gsub!(regex, "#{pixel}\\0")
        else
          raw_source << pixel
        end
      end
    end

    def track_unsubscribe
      if html_part?
        body = (message.html_part || message).body
        doc = Nokogiri::HTML(body.raw_source)
        id = message["EMAIL-ENGINE-ID"].value
        doc.css("a[href]").each do |link|
          if link["href"].match("/unsubscribe")
            uri = parse_uri(link["href"])
            next unless trackable?(uri)
            url = default_url.gsub("$ID$", id).gsub("/click", "/unsubscribe")
            link["href"] = url
          end
        end
        body.raw_source.sub!(body.raw_source, doc.to_s)
      end
    end

    def track_links
      if html_part?
        body = (message.html_part || message).body

        doc = Nokogiri::HTML(body.raw_source)
        id = message["EMAIL-ENGINE-ID"].value
        doc.css("a[href]").each do |link|
          uri = parse_uri(link["href"])
          next unless trackable?(uri)

          params = uri.query_values || {}
          if options[:utm_params] && !skip_attribute?(link, "utm-params")
            UTM_PARAMETERS.each do |key|
              params[key] ||= options[key.to_sym] if options[key.to_sym]
            end
          end
          uri.query_values = params

          if options[:click] && !skip_attribute?(link, "click")
            redirect_uri = uri.to_s
            signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), EmailEngine.secret_token, redirect_uri)
            uri = parse_uri(default_url.gsub("$ID$", id))
            uri.query_values = { signature: signature, url: redirect_uri }
          end

          link["href"] = uri.to_s
        end
        body.raw_source.sub!(body.raw_source, doc.to_s)
      end
    end

    def html_part?
      (message.html_part || message).content_type =~ /html/
    end

    def skip_attribute?(link, suffix)
      attribute = "data-skip-#{suffix}"
      if link[attribute]
        link.remove_attribute(attribute)
        true
      else
        false
      end
    end

    def trackable?(uri)
      uri && uri.absolute? && %w(http https).include?(uri.scheme)
    end

    def parse_uri(href)
      Addressable::URI.parse(href.to_s) rescue nil
    end
  end
end
