require "open-uri"

module FontFamily
  def find_font_name_only(query="")
    req_url = URI.parse("http://new.myfonts.com/")

    http = Net::HTTP.new(req_url.host, req_url.port)
    path = "/rest/di493gjwir/MyFontsSearch/autocomplete.json?"
    params = {:q => query}.to_param
    url = path + params
    req = Net::HTTP::Get.new(url)
    res = http.request(req)

    font_names = []
    response = JSON.parse(res.body)
    if response["success"]
      response["result"].each do |result|
        font_names << {:name => result}
      end
    end
    font_names
  end

  def font_details(query="")
    req_url = URI.parse("http://new.myfonts.com/")

    http = Net::HTTP.new(req_url.host, req_url.port)
    params = {:searchText => query, :resultType => "fonts"}.to_param
    url = "/rest/di493gjwir/MyFontsSearch/search.json?" + params
    req = Net::HTTP::Get.new(url)
    res = http.request(req)

    font_names = []
    response = JSON.parse(res.body)
    if response["success"]
      response["result"]["results"].each do |result|
        sub_font_count = result["description"].match(/\d/).to_s
        font_names << {:name => result["name"], :image => result["sampleImage"], :font_url => result["myfontsURL"], :uniqueid => result["uniqueID"], :id => result["id"], :count => sub_font_count}
      end
    font_names
    end
  end

  def sub_font_details(font_unique_id)
    req_url = URI.parse("http://new.myfonts.com/")

    http = Net::HTTP.new(req_url.host, req_url.port)
    params = {:uniqueid => font_unique_id}.to_param
    url = "/rest/di493gjwir/MyFontsDetails/getDetails.json?" + params
    req = Net::HTTP::Get.new(url)
    res = http.request(req)

    sub_font_names = []
    response = JSON.parse(res.body)
    if response["success"]
      response["result"].each do |result|
        result["styles"].each do |style|
          font_url = style["myfontsURL"].blank? ? "" : "http://new.myfonts.com/" + style["myfontsURL"]
          sub_font_names << {:name => style["name"], :image => style["sampleImage"], :font_url => font_url, :uniqueid => result["uniqueID"], :id => style["id"]}
        end
      end
    sub_font_names
    end
  end

  def get_family_details(id)
    req_url = URI.parse("http://new.myfonts.com/")

    http = Net::HTTP.new(req_url.host, req_url.port)
    params = {:idlist => id}.to_param
    url = "/rest/di493gjwir/MyFontsDetails/getFontFamilyDetails.json?" + params
    req = Net::HTTP::Get.new(url)
    res = http.request(req)

    response = JSON.parse(res.body)
    if response["success"]
      result = response["result"].first
      font_details = {:name => result["name"], :image => result["sampleImage"], :font_url => result["myfontsURL"], :uniqueid => result["uniqueID"], :id => result["id"]}
    end
  end

  def self.font_sample(id, text)
    params = { :id => id, :render_string => text }
    request('MyFontsSample/familySample.json', params)
  end

private

  def self.client
    req_url = URI.parse("http://new.myfonts.com/")
    @client ||= Net::HTTP.new(req_url.host, req_url.port)
  end

  # accepts path string and params hash
  def self.request(path, params)
    url = '/rest/di493gjwir/' + path + "?#{params.to_param}"
    req = Net::HTTP::Get.new(url)
    res = client.request(req)

    if url.match(/\.json/)
      response = JSON.parse(res.body)
      response["success"] ? response["result"] : nil
    else
      res.body
    end
  end

end
