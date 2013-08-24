require 'open-uri'
require 'net/http'
require 'json'

module MyFontsApiClient
  class << self

    def font_autocomplete(query)
      params = { :name => query, :name_type => 'startswith' }
      fonts = request(params) || {}
      fonts.values.collect { |f| f['name'] }.uniq
    end

    def fonts_list(query)
      params = {:searchText => query, :resultType => "fonts"}
      resp = request('MyFontsSearch/search.json', params) || {'results' => []}

      resp["results"].collect do |result|
        sub_font_count = result["description"].match(/\d/).to_s
        img_url = result["sampleImage"].match(/(.*)src=(.*)style=(.*)/) && $2.to_s.strip.gsub("\"", '')
        {
          :name => result["name"], :image => img_url,
          :font_url => result["myfontsURL"], :uniqueid => result["uniqueID"],
          :id => result["id"], :count => sub_font_count
        }
      end
    end

    def sub_fonts_list(font_unique_id)
      params = {:uniqueid => font_unique_id}
      resp = request('MyFontsDetails/getDetails.json', params) || []

      resp.collect do |result|
        result["styles"].collect do |style|
          font_url = style["myfontsURL"].blank? ? "" : "http://new.myfonts.com/" + style["myfontsURL"]
          img_url = style["sampleImage"].match(/(.*)src=(.*)style=(.*)/) && $2.to_s.strip.gsub("\"", '')
          {
            :name => style["name"], :image => img_url,
            :font_url => font_url, :uniqueid => result["uniqueID"], :id => style["id"]
          }
        end
      end.flatten
    end

    # get details for a single font/sub font
    def font_details(family_id, style_id = nil)
      params = { :extra_data => 'meta|article_abstract' }
      style_id.blank? ? params[:id] = family_id : params[:style_id] = style_id
      fonts = request(params) || {}

      details = fonts.values.first
      if details
        img_url = font_sample(family_id, style_id)
        owner = details['foundry'].first['name']
        {
          :name => details['name'], :image => img_url, :font_url => details['url'],
          :id => details['id'], :desc => details['article_abstract'].first, :owner => owner
        }
      end
    end

    # To periodically store foundry details for new fonts in local DB
    def font_foundry_details(family_ids = [])
      params = { :id => family_ids.join('|'), :extra_data => 'meta' }
      fonts = request(params) || {}

      fonts.values.inject({}) do |res, fnt|
        res.merge(fnt['id'] => fnt['foundry'].first['name'])
      end
    end

    def font_sample(family_id, style_id = nil, opts = {})
      opts.reverse_update(:text => 'fargopudmixy', :format => 'png', :fg => 666666, :size => 60)
      url = 'http://apicdn.myfonts.net/v1/fontsample?' + opts.to_param

      url << if style_id.blank?
        "&id=#{family_id}&idtype=familyid"
      else
        "&id=#{style_id}"
      end
    end

  private

    def client
      req_url = URI.parse("http://api.myfonts.net/")
      @client ||= Net::HTTP.new(req_url.host, req_url.port)
    end

    # Returns the `results`(hash) on success and nil on failure
    def request(params)
      params[:api_key] = SECURE_TREE['myfonts_api_key']
      can_paginate = params.delete(:do_pagination) || false
      path = "/v1/family?#{params.to_param}"

      req = Net::HTTP::Get.new(path)
      res = client.request(req)
      parsed_res = JSON.parse(res.body)

      if res.code == '200'
        total_results = parsed_res['total_results'].to_i
        results = parsed_res['results']
        return results unless can_paginate
        fetch_all_results(total_results, results, params)
      else
        logger.fatal parsed_res['error']
        nil
      end
    end

    # recursively fetch all page results and return them as one collection
    # Assumes the search is more relevant and won't go beyond 3 pages(150 results)
    def fetch_all_results(total_count, results, params)
      all_results ||= {}
      all_results.update(results)
      return all_results if all_results.length == total_count

      prev_page = params[:page] || 0
      params.update(:page => prev_page + 1)
      request(params)
    end
  end # class#self
end # module
