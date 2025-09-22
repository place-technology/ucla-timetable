class UCLA::Timetable
  private def generate_cache_key(*args : String) : String
    Digest::MD5.hexdigest(args.join)
  end

  protected def to_klass(klass, payload)
    klass.from_json(payload)
  rescue error : JSON::Error
    Timetable.logger.error(exception: error) { "error parsing #{klass}: --\n#{payload}\n-----------------" }
    raise error
  end

  def request(klass, url : String, method : String = "GET", cache : String? = nil)
    # check if the data is in the cache
    if cache && (cached = @cache[cache]?)
      cached_response, timestamp = cached
      return to_klass(klass, cached_response) if Time.utc < timestamp
    end

    # check if host included, mostly from next page links
    uri = URI.parse url
    url = uri.host.presence ? url : File.join(@host, url)
    response = HTTP::Client.exec(method, url, headers: headers)
    raise "HTTP error requesting: #{method} #{url}\n#{response.status_code} - #{response.body}" unless response.success?

    Timetable.logger.debug { "\n  - request: #{method} #{url}" }
    Timetable.logger.trace { "\n    status: #{response.status_code}\n    response: #{response.body}" }

    # cache the response
    resp_payload = response.body
    @cache[cache] = {resp_payload, CACHE_EXPIRATION.from_now} if cache
    to_klass klass, resp_payload
  end
end
