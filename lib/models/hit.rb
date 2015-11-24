

module Linkshortener
  class Hit
    property :referrer, String  # Where did the person access from (if available)
    property :time, DateTime    # what time did the access happen
    property :followed, Boolean, # was the link followed
             :default => true
    belongs_to :link
  end
end
