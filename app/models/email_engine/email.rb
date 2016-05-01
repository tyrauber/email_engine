module EmailEngine
  class Email
    attr_accessor :id, :to, :from, :subject, :headers, :click_url, :bounce_response, :complaint_response
    attr_accessor :sent_at, :open_at, :click_at, :bounce_at, :complaint_at
    attr_accessor :sent, :open, :click, :bounce, :complaint, :state
     
    def initialize(message)
      @id = message['id'] || message['EMAIL-ENGINE-ID'].try(:value)
      @to = message['to'].try(:value) || message['to']
      @from = message['from'].try(:value) || message['from']
      @subject = message['subject'].try(:value) || message['subject']
      @headers = message['headers']  || JSON.parse(message['EMAIL-ENGINE-HEADERS'].try(:value) || '{}')
      ['sent', 'open', 'click', 'bounce', 'complaint'].each do |action|
        if message["#{action}_at"]
          instance_variable_set("@#{action}_at", message["#{action}_at"])
          instance_variable_set("@#{action}", !!(message["#{action}_at"]))
        end
      end
      @click_url = message['click_url']
      @bounce_response = message['bounce_response']
      @complaint_response = message['complaint_response']
      @state = message['state'] || current_state
      self.body = (message.try(:html_part) || message).try(:body).try(:raw_source) || message['body']
    end

    def current_state
      self.complaint_at ? 'complaint' : (self.bounce_at ? 'bounce' : (self.click_at ? 'click' : (self.open_at ? 'open' : 'sent')))
    end

    def sent_at_dt
      DateTime.strptime(sent_at.to_s,'%s')
    end

    def method_missing(m, *args, &block)
      return headers[m.to_s] if headers.include?(m.to_s)
      raise "NoMethodError: undefined method '#{m}' for EmailEngine::Email"
    end

    def save!(action=:sent, atts={})
      atts.each{ |k,v| self.send("#{k}=", v) }
      self.send("#{action}_at=", Time.now)
      instance_variable_set("@state", current_state)
      date = DateTime.strptime((id.to_i/1000).to_s,'%s').utc.freeze
      id = self.id.freeze
      EmailEngine.redis.multi do
        EmailEngine.redis.zadd(self.class.table_name('search'), id, self.to_json) if action == :sent # Scan & match
        #p "SHOULD update hget #{self.class.table_name} #{id}"
        #EmailEngine.redis.zadd(self.class.table_name(action.to_s), id, self.to_json) # Paginate
        #p "SHOULD ADD zrangebyscore #{self.class.table_name}:#{action} #{id} #{id}"
        EmailEngine.redis.hset(self.class.table_name, id, self.to_json) # Updateable
        self.class.date_formats.each do |k,d|
          EmailEngine.redis.hincrby("email_engine:stats:per_#{k}", "#{action}/#{date.strftime(d)}", 1) # Dates
        end
      end
      test! if action == :sent
    end

    def body
      EmailEngine.redis.get("email_engine:content:#{id}")
    end

    def body=(value)
      if !!(value.present? && EmailEngine.configuration.store_email_content)
        EmailEngine.redis.setex("email_engine:content:#{self.id}", EmailEngine.configuration.expire_email_content.to_i, value)
        self.body = nil
      end
    end
    
    def test!
      if ([true, false].sample)
        save!(:open)
        if ([true, false].sample)
          save!(:click)
          if ([true, false].sample)
            save!(:bounce)
            if ([true, false].sample)
              save!(:complaint)
            end
          end
        end
      end
    end

    protected

    # def setup_autocomplete
    #   # Zrangebylex autocomplete
    #   # zrangebylex email_engine:email:autocomplete - +
    #   # zrangebylex email_engine:email:autocomplete [query +
    #   if action == :sent
    #     hash = [{to: @to}, {subject: @subject}, @headers].reduce(&:merge)
    #     hash.each do |k,v|
    #       EmailEngine.redis.zadd("#{self.class.table_name}:autocomplete", 0, "#{CGI.escape(v.downcase)}:#{self.id}")
    #     end
    #   end
    # end
    
    # def autocomplete(query, cursor=0, limit=30)
    #   keys = EmailEngine.redis.zrangebylex("#{table_name}:autocomplete", "[#{query}", "+").map{|k| k.split(":").last }
    #   records = EmailEngine.redis.hmget(table_name, keys.uniq.map(&:to_i)) unless keys.empty?
    #   unless records.empty?
    #     emails = records.map{|record| Email.new(JSON.parse(record)) }
    #   else
    #     return []
    #   end
    # end
    #
    # def search(query, cursor=0, limit=30)
    #   records = EmailEngine.redis.zscan(table_name, cursor, match: "*#{query}*", count: limit)
    #   #Rails.logger.info "zscan #{table_name} #{cursor} MATCH *#{query}* COUNT #{limit}"
    #   #keys = EmailEngine.redis.zscan(table_name, cursor, match: "*#{query}*", count: limit)
    #   #records = EmailEngine.redis.hmget(table_name, keys.map(&:to_i)) unless keys.empty?
    #   unless records.empty?
    #     emails = records[1].map{|record| Email.new(JSON.parse(record[0])) }
    #   else
    #     return []
    #   end
    # end

    class << self

      def table_name(action=nil)
        [name.underscore.gsub("/", ":"), action].compact.join(":")
      end

      def date_formats(w=nil)
        #iso8601: 2016-04-27T22:21:00Z
        {
          second: "%Y-%m-%dT%H:%M:%SZ",
          minute: "%Y-%m-%dT%H:%M#{w ? '*' : ':00Z'}",
          hour: "%Y-%m-%dT%H#{w ? '*' : ':00:00Z'}",
          day: "%Y-%m-%d#{w ? '*' : 'T00:00:00Z'}",
          month: "%Y-%m#{w ? '*' : '-00T00:00:00Z'}",
          year: "%Y#{w ? '*' : '-00-00T00:00:00Z'}"
        }
      end

      def all(opts={}, records= [], response=[])
        opts[:offset] ||= 0
        opts[:limit] ||= 30
        while
          #p "zrevrangebyscore #{table_name('search')} #{opts[:finish]||"+inf"} #{opts[:start]||"-inf"} COUNT #{opts[:offset]||0} #{opts[:limit]||30} withscores"
          keys = EmailEngine.redis.zrevrangebyscore("#{table_name('search')}", (opts[:finish]||"+inf"), (opts[:start]||"-inf"), limit: [opts[:offset], opts[:limit]], withscores: true).to_h.values
          #p "hmget #{table_name} #{keys.map(&:to_i).join(" ")}"
          records = keys.empty? ? [] : EmailEngine.redis.hmget(table_name, keys.map(&:to_i))
          records.compact.each do |record| 
            response.push filter_response(record, opts)
          end
          response.compact!
          opts[:offset] += opts[:limit]
          break if response.length >= opts[:limit].to_i || records.length == 0
        end
        return response
      end
      
      def filter_response(record, opts)
        json = JSON.parse(record)
        if (opts[:type].nil? || opts[:type] == 'sent' || json['state'] == opts[:type])
           return new(json)
        end
        return nil
      end

      def find(id)
        all(start: id, finish: id).first
      end

      def last(opts={})
        all({start: '-inf', finish: '+inf', offset: 0, limit: 1}).first
      end
    end
  end
end