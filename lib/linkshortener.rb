
require 'sinatra/base'
require 'data_mapper'
require 'liquid'
require 'pp'
require File.join File.dirname(__FILE__),'models/link'

module Linkshortener
  class App < Sinatra::Base

    configure do
      set :site_name, "foxiepa.ws"
    end 
    
    configure :development do
      set :views, "#{ENV["HOME"]}/linkshortener/views/"
      set :datastores, { :default =>
                         "sqlite://#{ENV["HOME"]}/linkshortener/debug.db" }
    end
    Liquid::Template.file_system = Liquid::LocalFileSystem.new(settings.views)
    helpers do 
      def stats(link)
        dnt = env[:HTTP_DNT] > 0
        if dnt 
          if settings.always_track_hitcount then
            Hit.create(
              :time => Time.now,
              :link => link.id
            )
          end
        else
          Hit.create(
            :user_agent => request.user_agent,
            :referrer => request.referrer,
            :time => Time.now,
            :link => link.id
          )
        end
      end
    end
    
    settings.datastores.each do |store,dsn|
      DataMapper::setup(store,dsn)
    end
    DataMapper.finalize
    Link.auto_upgrade!
    #Hit.auto_upgrade!
    
    get '/' do
      # show a pretty index page
      liquid :index, :locals => { :sitename => settings.site_name }
    end
    
    get '/create' do
      liquid :create, :locals => { :sitename => settings.site_name }
    end
    
    post '/create' do
      # if we failed
          
      
        liquid :failedCreate,
               :locals => { :sitename => settings.site_name }
    end
    
    get '/:lug' do |lug|
      begin
        pp(request)
        link = Link.get!(lug)
        if link.trigger then
          print "passing to /preview"
          return call env.merge("PATH_INFO" => "/preview/#{lug}")
        end
        
        # we will /not/ do statistics until DNT works.
        stats link

        redirect link.link
      rescue DataMapper::ObjectNotFoundError
        pass
      end 
    end
    
    get '/preview/:lug' do |lug|
      begin
        link = Link.get!(lug)
        stats link
        liquid :preview, :locals => { :site_name => settings.site_name,
                                      :link => link.link.to_s,
                                      :triggerContent => link.triggerContent
                                    }
      rescue DataMapper::ObjectNotFoundError
        "other fail"
      end
    end
    
    get '/stats' do
      
    end
    
  end
end
