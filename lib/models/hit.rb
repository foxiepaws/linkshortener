

module Linkshortener
  class Hit
    include DataMapper::Resource
    property :id, Serial
    property :referrer, URI  # Where did the person access from (if available)
    property :time, EpochTime    # what time did the access happen
    property :user_agent, Text
    
    belongs_to :link
  end
end
