
require 'sinatra/base'
require 'data_mapper'
require 'liquid'
require 'pp'
require 'ipaddr'
require File.join File.dirname(__FILE__),'models/link'
require File.join File.dirname(__FILE__),'models/hit'

module Linkshortener
  class App < Sinatra::Base

    configure do
      set :site_name, "foxiepa.ws"
      set :default_slug_length, 10
      set :always_track_hitcount, true
    end 
    
    configure :development do
      set :views, "#{ENV["HOME"]}/linkshortener/views/"
      set :datastores, { :default =>
                         "sqlite://#{ENV["HOME"]}/linkshortener/debug.db" }
    end
    Liquid::Template.file_system =
      Liquid::LocalFileSystem.new(settings.views)



    settings.datastores.each do |store,dsn|
      DataMapper::setup(store,dsn)
    end

    DataMapper.finalize
    Link.auto_upgrade!
    Hit.auto_upgrade!
    Link.raise_on_save_failure = true
    Hit.raise_on_save_failure = true
    
    helpers do 
      def stats(link)
        dnt = (env['HTTP_DNT'] =~ /^1$/) ? true : false
        print "stats routine: dnt on? " + dnt.to_s +
              " tracking anyway? " + settings.always_track_hitcount.
                                     to_s + "\n"
        begin 
          if dnt 
            if settings.always_track_hitcount then
              Hit.create(
                :time => Time.now,
                :link => link
              )
            end
          else
            Hit.create(
              :user_agent => request.user_agent,
              :referrer => request.referrer,
              :time => Time.now,
              :link => link
            )
          end
        rescue DataMapper::SaveFailureError => e
          print "DEBUG: " + e.resource.errors.inspect.to_s
        end
      end
    end
    
       
    get '/' do
      # show a pretty index page
      liquid :index, :locals => { :sitename => settings.site_name }
    end
    
    get '/create' do
      liquid :create, :locals => { :page_title => "Add Link",
                                   :sitename => settings.site_name }
    end
    
    post '/create' do

      # a bit of a nasty hack with regards to flow control.
      def genSlug()
        slug = rand(36**settings.default_slug_length).to_s(36)
        return slug
      end

      customSlug     = params['customSlug']
      trigger        = (params['tw'] =~ /^on$/) ? true : false
      triggerContent = params['triggerContent']
      link           = params['linkAddress']

      if customSlug != "" then
        if customSlug =~ /^[a-zA-Z0-9\-]+$/ then
            begin
              res = Link.create(
                :slug => customSlug,
                :trigger => trigger,
                :triggerContent => triggerContent,
                :link           => link,
                :added          => Time.now,
                :ipaddr         => IPAddr.new(request.ip)
                
              )
              success = true
            rescue DataMapper::SaveFailureError => e
              slug = customSlug
              success = false 
              errormsg = "DEBUG: " + e.resource.errors.inspect.to_s
            rescue DataObjects::IntegrityError => e
              if e.to_s =~ /UNIQUE constraint failed/ then
                errormsg = "That custom slug is already in use."
              else
                errormsg = "DEBUG: e.to_s"
              end
              slug = customSlug
              success = false
            end
        else
          success = false
          errormsg =            "The custom slug provided is invalid. Only the ASCII characters A through Z, a though z, 0 through 9, and - are allowed."
        end
      else
        slug = genSlug()
        
        begin
          res = Link.create(
            :slug => slug,
            :trigger => trigger,
            :triggerContent => triggerContent,
            :link => link,
            :added => Time.now,
            :ipaddr => IPAddr.new(request.ip)
          )
          success = true
        rescue DataMapper::SaveFailureError => e
          success = false
          errormsg = "DEBUG: " + e.resource.errors.inspect.to_s
        end
        
        if not success then
          errormsg =
            "Something went wrong adding the link. please try again"
        end
      end
      
      if success
       return call env.merge("PATH_INFO" => "/stats/#{slug}")
      else
              liquid :create,
                     :locals => { :page_title => "Add Link",
                                  :sitename => settings.site_name,
                                  :errormsg => errormsg }

      end                  
      #                          }
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
                                      :trigger => link.trigger,
                                      :triggerContent => link.triggerContent
                                    }
      rescue DataMapper::ObjectNotFoundError
        "other fail"
      end
    end

    get '/previewtest' do 
      liquid :preview, :locals => { :sitename => settings.site_name,
                           :link => "/",
                           :trigger => false }
    end

    get '/previewtest_trigger' do
      liquid :preview, :locals => { :sitename => settings.site_name,
                           :link => "/",
                           :trigger => true,
                           :triggerContent => "NSFW"
                         }
    end
      
    get '/stats' do
      "Links: " + Link.count.to_s +
        "Links with trigger warnings: " +
        Link.count(:conditions => [ 'trigger = ?', true ]).to_s +
        "total views: " + Hit.count.to_s
    end
    get '/about' do
      liquid :about, :locals => { :site_name => settings.site_name,
                                  :page_title => "About" }
    end
  end
end
