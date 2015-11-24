

module Linkshortener
  class Link
    include DataMapper::Resource
    
    property :lug, String, :key => true
    property :link, URI, :required => true, :unique => true 
    property :trigger, Boolean, :required => true, :lazy => false,
             :default => true
    property :triggerContent, Text
    property :added, DateTime
    property :ipaddr, IPAddress, :required => true
    # TODO: add stats.
    #has n, :hits
  end 
end 
