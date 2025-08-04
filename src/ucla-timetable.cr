require "http/client"
require "log"
require "json"
require "base64"
require "uri"
require "time"
require "digest/md5"

module UCLA
  TIMEZONE = Time::Location.load("America/Los_Angeles")

  class Timetable
    {% begin %}
      VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
    {% end %}

    Log              = ::Log.for(self)
    CACHE_EXPIRATION = 10.minutes
  end
end

require "./ucla-timetable/models/*"
require "./ucla-timetable/*"
