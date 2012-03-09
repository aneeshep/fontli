# See how all your routes lay out with "rake routes"
Fontli::Application.routes.draw do
  # Api controller
  match '/api/:action(.:format)', :controller => 'api_actions'

  # feeds controller
  match 'feeds' => 'feeds#index', :as => :feeds
  match 'post-feed' => 'feeds#post_feed', :as => :post_feed
  match 'publish-feed/:id' => 'feeds#publish_feed', :as => :publish_feed
  match 'socialize-feed/:id' => 'feeds#socialize_feed', :as => :socialize_feed
  match 'detail_view' => 'feeds#detail_view', :as => :detail_view
  match 'get_mentions_list' => 'feeds#get_mentions_list', :as => :get_mentions_list

  # fonts controller
  match 'tag_font' => 'fonts#tag_font', :as => :tag_font
  match "fetch_font_families" => "fonts#fetch_font_families", :as => :fetch_font_families
  match "get_font_details" => "fonts#get_font_details", :as => :get_font_details
  match "get_sub_font_details" => "fonts#get_sub_font_details", :as => :get_sub_font_details

  # welcome controller
  root :to => 'welcome#index'

  match 'signup/:platform' => 'welcome#signup', :as => :signup
  match 'login/:platform'  => 'welcome#login',  :as => :login
  match 'auth/:platform/callback' => 'welcome#auth_callback', :as => :auth_callback
  match 'logout' => 'welcome#logout', :as => :logout

  # Utils
  constraints :host => /(localhost|chennai\.pramati\.com)/i do
    match 'doc' => 'welcome#api_doc'
  end

  # Permalink - Has to be the last one
  match '*url' => 'welcome#permalink'
end
