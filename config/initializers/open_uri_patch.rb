require 'open-uri'

# make OpenURI to use tempfiles instead of io.
# Patched from http://snippets.dzone.com/posts/show/3994
OpenURI::Buffer.module_eval do 
  remove_const :StringMax
  const_set :StringMax, 0
end
