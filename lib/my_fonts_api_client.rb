require 'open-uri'
require 'net/http'
require 'json'

module MyFontsApiClient
  class << self
    def font_autocomplete(query)
      params = { :name => query, :name_type => 'startswith' }
      fonts = request(params)
      fonts.values.collect { |f| f['name'] }.uniq
    end

    # with exact font name, find its variants from different publishers
    def fonts_list(query)
      params = { :name => query } # name_type => 'exact'
      fonts = request(params)

      fonts.values.collect do |f|
        fnt = get_attrs(f)
      end
    end

    # Get details with name. Only to be used when 
    # there's just one font in this exact same name.
    def font_details_with_name(name)
      params = { :name => name, :extra_data => 'details|article_abstract' }
      fonts = request(params)

      details = fonts.values.first || {}
      return details if details.empty?
      get_attrs(details)
    end

    # with a family_id find its complete details - styles, desc, publisher
    def font_details(family_id, style_id = nil)
      params = { :id => family_id, :extra_data => 'details|styles|article_abstract' }
      # When style_id is available, its safer to find details by style_id,
      # coz there's no guarantee that we have the correct family_id passed.
      unless style_id.blank?
        params.delete(:id)
        params[:style_id] = style_id
      end
      fonts = request(params)

      details = fonts.values.first
      return {} unless details

      fnt = get_attrs(details)
      f = { :id => details['id'] }
      fnt[:styles] = details['styles'].collect do |style|
        get_attrs(f, style)
      end
      fnt
    end

    # There's no API to find details of a sub font, directly
    # Its only a wrapper to find it using `font_details`
    # Returns the font details with just one :style
    def subfont_details(family_id, style_id)
      details = self.font_details(family_id, style_id)
      return details if details.blank?

      style = details.delete(:styles).detect { |s| s[:id] == style_id.to_i }
      details.merge(:styles => [style].compact)
    end

    # Wrapper to get details of a font(without styles) or subfont
    def details_for(family_id, style_id = nil)
      details = if style_id.blank?
        self.font_details(family_id).merge(:styles => [])
      else
        self.subfont_details(family_id, style_id)
      end
      details
    end

    # generate the myfonts cdn url to the samples. No real API call here.
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
      Stat.current.increment_myfonts_api_access_count!
      parsed_res = JSON.parse(res.body)

      if res.code == '200'
        total_results = parsed_res['total_results'].to_i
        results = parsed_res['results'] || {}
        return results unless can_paginate
        fetch_all_results(total_results, results, params)
      else
        logger.fatal(parsed_res['error']) if defined?(logger)
        puts parsed_res['error']
        return {}
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

    # return hash of :name, :id, ... for a font or subfont
    def get_attrs(font, style = nil)
      owner = font['publisher'].try(:first).try(:[], 'name')
      abstract = font['article_abstract'].try(:first)
      family_id, style_id = font['id'], style.try(:[], 'id')
      img_url = font_sample(family_id, style_id)

      style ||= font
      {
        :name => style['name'], :image => img_url, :id => style['id'].to_i,
        :url => style['url'], :owner => owner, :desc => abstract
      }
    end
  end # class#self
end # module
