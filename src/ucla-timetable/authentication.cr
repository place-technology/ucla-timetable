class UCLA::Timetable
  def initialize(@host : String, @client_id : String, @client_secret : String)
    @token = ""
    @expires_at = Time.unix(0)
    @cache = Hash(String, Tuple(String, Time)).new
  end

  def get_access_token : String
    if @token.empty? || Time.utc.to_unix >= @expires_at.to_unix
      Timetable.logger.debug { "⚠️ Access token expired or missing. Refreshing..." }
      fetch_new_access_token
    else
      Timetable.logger.trace { "✅ Using existing access token" }
      @token
    end
  end

  def fetch_new_access_token : String
    url = "#{@host}/oauth/client_credential/accesstoken?grant_type=client_credentials"
    credentials = "#{@client_id}:#{@client_secret}"
    encoded_credentials = Base64.strict_encode(credentials)

    headers = HTTP::Headers{
      "Authorization" => "Basic #{encoded_credentials}",
      "Content-Type"  => "application/x-www-form-urlencoded",
      "Accept"        => "application/json, text/plain, text/json, */*",
    }
    form = URI::Params.build do |body|
      body.add "scope", "read"
    end

    response = HTTP::Client.post(url, headers: headers, body: form)
    raise "HTTP error: #{response.status_code} - #{response.body}" if response.status_code >= 400

    Timetable.logger.trace { "Authentication response:\n#{response.body}" }
    json = JSON.parse(response.body)
    raise "Failed to retrieve access token: #{json}" unless json["access_token"]?

    @token = json["access_token"].as_s
    expires_in = json["expires_in"].as_s.to_i64
    @expires_at = Time.unix(Time.utc.to_unix + expires_in - 60)

    Timetable.logger.debug { "🔄 Access token refreshed" }
    @token
  end

  def headers
    HTTP::Headers{
      "Authorization" => "Bearer #{get_access_token}",
      "Content-Type"  => "application/json",
    }
  end
end
