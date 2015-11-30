require 'sinatra/base'
require 'data_mapper'
require 'ipaddr'

module Linkshortener
  module StatsUtils
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
end
