module EmailEngine
  class AdminController < ActionController::Base
    layout "email_engine/application"

    before_filter do
      # Set Defaults
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
  end
end