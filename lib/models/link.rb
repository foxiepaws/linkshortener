

module Linkshortener
  class Link
    include DataMapper::Resource
    
    property :slug, String, :key => true
    property :link, URI, :required => true
    property :trigger, Boolean, :required => true, :lazy => false,
             :default => true
    property :triggerContent, Text
    property :added, EpochTime
    property :ipaddr, IPAddress, :required => true
    # TODO: add stats.
    has n, :hits
  end 
end 
