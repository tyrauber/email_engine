module EmailEngine
  class Processor
    attr_reader :message, :mailer, :options,:utm_parameters, :extra_attributes

    UTM_PARAMETERS = %w(utm_source utm_medium utm_term utm_content utm_campaign).map(&:to_sym)
    OPTIONALS = %w(send open click utm_params unsubscribe).map(&:to_sym)

    def initialize(message, mailer = nil)
      @message = message
      @mailer = mailer
      @options = JSON.parse(message['EMAIL-ENGINE-OPTIONS'].try(:value) || '{}')
      @utm_parameters = JSON.parse(message['EMAIL-ENGINE-UTM-PARAMETERS'].try(:value) || '{}')
      @extra_attributes = JSON.parse(message['EMAIL-ENGINE-EXTRA-ATTRIBUTES'].try(:value) || '{}')
    end


    def assign_attributes(key = :utm_parameters, only = nil, opts ={})
      opts.each do |k,v|
        if only.nil? || only == k || only.to_a.include?(k)
          value =  ((v).class == Proc) ? v.call(@message, @mailer) : v
          instance_variable_set("@#{key.to_sym}",  instance_variable_get("@#{key.to_sym}").merge(k.to_sym => value))
        end
      end
      instance_variable_get("@#{key.to_sym}")
    end

    def process
      safely do
        message['EMAIL-ENGINE-ID'] = token.dup
        message['EMAIL-ENGINE-UTM-PARAMETERS'] = assign_attributes(:utm_parameters, UTM_PARAMETERS, mailer.email_engine_options).compact.to_json
        message['EMAIL-ENGINE-EXTRA-ATTRIBUTES'] = assign_attributes(:extra_attributes, nil, (mailer.email_engine_options['extra'] || {})).compact.to_json
        message['EMAIL-ENGINE-OPTIONS'] = assign_attributes(:options, OPTIONALS, mailer.email_engine_options).compact.to_json
      end
    end

    def deliver
      safely do
        if (message["EMAIL-ENGINE-ID"]) && message.perform_deliveries
          track_unsubscribe if options['unsubscribe']
          track_open if options['open']
          track_links if options['utm_params'] || options['click']
          track_send if options['send']
          message['EMAIL-ENGINE-EXTRA-ATTRIBUTES'] = nil
          message['EMAIL-ENGINE-UTM-PARAMETERS'] = nil
          message['EMAIL-ENGINE-OPTIONS'] = nil
        end
      end
    end

    protected

    def default_url
      @opt ||= EmailEngine::Engine.routes.url_helpers.url_for((ActionMailer::Base.default_url_options || {}).merge(controller: "email_engine/emails", action: "click", id: "$ID$"))
    end

    def token
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
            params = (uri.query_values || {}).merge!(email_id: id)
            uri.query_values = params
            link["href"] = uri.to_s
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
          if options['utm_params'] && !skip_attribute?(link, "utm-params")
            params.merge!(utm_parameters)
          end
          uri.query_values = params
          if options['click'] && !skip_attribute?(link, "click")
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
