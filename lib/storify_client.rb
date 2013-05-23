module StorifyClient

  def self.fetch_story(limit=5)
    res = request(:per_page => limit)
    res.compact.empty? ? default_story : res
  end

private

  def self.client
    req_url = URI.parse("http://api.storify.com/")
    client = Net::HTTP.new(req_url.host, req_url.port)

    client.open_timeout = 2
    client.read_timeout = 1
    client
  end

  # accepts path string and params hash
  def self.request(params)
    params[:api_key] = SECURE_TREE['storify_api_key']
    url = '/v1/stories/Fontli/fontli-buzz/elements' + "?#{params.to_param}"
    req = Net::HTTP::Get.new(url)

    begin
      res = client.request(req)
      content = JSON.parse(res.body)['content']
    rescue Exception => ex
      STDERR.puts "StorifyClient failure - #{ex.message}"
      content = nil
    end

    return [] if content.blank? || content['elements'].blank?
    parsed_response content['elements']
  end

  def self.parsed_response(elements)
    return [] if elements.blank?
    STDERR.puts "Parsing #{elements.length} stories from Storify"
    elements.collect do |elem|
      {
        :link   => elem['permalink'],
        :text   => elem['data']['quote']['text'],
        :name   => elem['attribution']['name'],
        :avatar => elem['attribution']['thumbnail']
      } rescue nil
    end
  end

  def self.default_story
    [{
      :link   => "",
      :text   => "I realized that I go all 'Patrick Bateman' everytime I see a business card. And then, I found this beautiful app called @fontli",
      :name   => 'Oscar Garcia',
      :avatar => '/web-assets/images/twitter-quote.png'
    }]
  end
end
