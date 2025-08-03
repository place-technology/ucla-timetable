require "http/client"
require "log"
require "json"
require "base64"
require "uri"
require "time"
require "digest/md5"

class UCLA::Timetable
  {% begin %}
    VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
  {% end %}

  Log              = ::Log.for(self)
  CACHE_EXPIRATION = 10.minutes
  TIMEZONE         = Time::Location.load("America/Los_Angeles")
end

require "./ucla-timetable/models/*"
require "./ucla-timetable/*"
