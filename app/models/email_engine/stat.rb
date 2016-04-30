module EmailEngine
  class Stat

    class << self

      def table_name
        "email_engine:stats"
      end

      def find(last="hour",interval="second",  match="*", cursor=0)
        array = []; response = []
        last_interval = 1.send(interval).ago.utc.strftime(EmailEngine::Email.date_formats[interval.to_sym])
        results = EmailEngine.redis.hscan("email_engine:stats:per_#{interval}", cursor, match: match)[1].to_h
        ['sent', 'open', 'click', 'bounce', 'complaint'].map {|k| array.push date_range(results).map{|d| results[k+"/"+d].to_i }.unshift(k) }
        array.unshift(date_range(results).map{|d| d }.unshift("x"))
        array.transpose.each {|x| response << x.join(",") }
        #response.push([last_interval,0,0,0,0,0].join(","))
        return response.join("\n")
      end
      
      def json(results)
        results = results[1].map { |k, v| { k.split(":")[1]  => { sent: 0, open: 0, click: 0, bounce: 0, complaint: 0, date: k.split(":")[1].to_i*1000, k.split(":")[0] => v }}}
        results = results.inject({}) { |h,v| h[v.keys.first] ||= []; h[v.keys.first] << v.values.first; h }
        results = results.map { |m| {m.first => m.last.flatten.inject(:merge)} }
        results = results.map{|k,v| k.map{|kk,vv| vv}}.flatten
      end
      
      def date_range(results)
        results.map{|k,v| k.split("/")[1]}.uniq.sort
      end

      def all(measurement='second', match="*")
        find(start, finish)
      end

      def last
        records = EmailEngine.redis.zrange(table_name, -1, -1)
        unless records.empty?
         return  new(JSON.parse(records.first))
        else
         raise ActiveRecord::RecordNotFound
        end
      end
  
      protected
    
      def search_key(type="*", last="hour" )
         "#{type}/#{Time.now.utc.strftime(date_formats("*")[last.to_sym])}"
      end
    end
  end
end