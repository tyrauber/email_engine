module EmailEngine
  class EmailsController < ActionController::Base

    layout "email_engine/application"

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, :alert => exception.message
    end

    if respond_to?('load_and_authorize_resource')
      before_filter do
        current_ability.merge(Ability.new(current_user))
      end
      load_and_authorize_resource class: Email, only: [:index, :show, :stats]
    end
    before_action :ses_subscription_confirmation, only: [:success, :bounce, :complaint]

    before_filter only: [:index, :stats] do
      params[:limit] ||= 30
      params[:offset] ||= 0
      params[:start] ||= '-inf'
      params[:finish] ||= '+inf'
      params[:last] ||= 'hour'
      params[:interval] ||= 'minute'
    end

    def index
      if request.format == 'json'
        if params[:query].present?
          @emails = EmailEngine::Email.search(params)
        else
          @emails = EmailEngine::Email.all(params)
        end
        render json: @emails.to_json
      end
    end

    def show
      @email = EmailEngine::Email.find(params[:id])
    end

    def stats
      render json: EmailEngine::Stat.find(params[:last],params[:interval])
    end
    
    def open
      # @email = Email.find(params[:id])
      # @email.save!(:open) if @email && !( @email.open || (request.referrer && request.referrer.match(ActionMailer::Base.default_url_options[:host])))
      send_data Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="), type: "image/gif", disposition: "inline"
    end

    def click
      url = params[:url].to_s
      # @email = Email.find(params[:id])
      # @email.save!(:click, { click_url: url }) if @email && !(@email.click || (request.referrer && request.referrer.match(ActionMailer::Base.default_url_options[:host])))
      signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), EmailEngine.secret_token, url)
      if secure_compare(params[:signature], signature)
        redirect_to url
      else
        redirect_to main_app.root_url
      end
    end

    def unsubscribe
      @email = Email.find(params[:id])
      EmailEngine::EmailHelper.unsubscribe_method!(@email)
    end

    def success
      return render json: {} unless aws_message_authentic? && message['notificationType'] == 'Success'
      message['success']['bouncedRecipients'].each do |recp|
        EmailEngine::EmailHelper.success_method!(recp)
      end
      render json: {}
    end

    def bounce
      return render json: {} unless aws_message_authentic? && message['notificationType'] == 'Bounce'
      message['bounce']['bouncedRecipients'].each do |recp|
        EmailEngine::EmailHelper.bounce_method!(recp)
        Email.find(params[:id]).save!(:bounce, { bounce_response: recp }) rescue nil
      end
      render json: {}
    end

    def complaint
      return render json: {} unless aws_message_authentic? && message['notificationType'] == 'Complaint'
      message['complaint']['complainedRecipients'].each do |recp|
        EmailEngine::EmailHelper.complaint_method!(recp)
        Email.find(params[:id]).save!(:complaint, { complaint_response: recp }) rescue nil
      end
      render json: {}
    end

    protected

    def aws_message_authentic?
      @aws_message_authentic ||= (Rails.env.test? || Aws::SNS::MessageVerifier.new.authentic?(request.raw_post))
    end

    def ses_subscription_confirmation
      response = open(message["SubscribeURL"]).read if message["SubscribeURL"].present?
    end

    def message
      @message ||= JSON.parse(JSON.parse(request.raw_post)['Message']) rescue JSON.parse(request.raw_post)
    end

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize
      l = a.unpack "C#{a.bytesize}"
      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end
end
