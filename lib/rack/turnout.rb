require 'rack'
require 'turnout'

class Rack::Turnout
  def initialize(app, config={})
    @app = app

    Turnout.config.update config

    if config[:app_root].nil? && app.respond_to?(:app_root)
      Turnout.config.app_root = app.app_root
    end
  end

  def call(env)
    settings = Turnout::MaintenanceFile.find

    if settings
      response = @app.call(env)
      request = Turnout::Request.new(env)
    end

    if settings && !request.allowed?(settings)
      page_class = Turnout::MaintenancePage.best_for(env)
      page = page_class.new(settings.reason)

      page.rack_response(settings.response_code, settings.retry_after)
    else
      response ||= @app.call(env)
    end
  end
end
