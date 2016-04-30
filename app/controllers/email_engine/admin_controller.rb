module EmailEngine
  class AdminController < ActionController::Base
    layout "email_engine/application"

    def index
      params[:type] ||= 'sent'
      params[:limit] ||= 30
      params[:offser] ||= 0

      if params[:query].present?
        @emails = EmailEngine::Email.search(params[:query])
      else
        @emails = EmailEngine::Email.all(offset: params[:offset], limit: params[:limit])
      end
      render json: @emails.to_json if request.format == 'json'
    end

    def show
      @email = EmailEngine::Email.find(params[:id])
    end

    def stats
      params[:last] ||= 'hour'
      params[:interval] ||= 'minute'
      params[:type] ||= '*';
      render json: EmailEngine::Stat.find(params[:last],params[:interval])
    end
  end
end