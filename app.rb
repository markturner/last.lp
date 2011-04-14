require 'rubygems'
require 'bundler'
Bundler.setup

require 'sinatra'
require 'rockstar'
require 'json'

configure do    
  # initialise api key
  Rockstar.lastfm = YAML.load_file('lastfm.yml')

  # get my user id
  user = Rockstar::User.new('markturner')
  
  # get albums
  @@albums = user.weekly_album_chart
  
end

get '/' do
  headers['Cache-Control'] = 'public, max-age=172800' # Cache for two days
  
  array = []
  
  @@albums.each do |a|
    # write load_info result to local variable to prevent repeated api calls
    info = a.load_info
    
    # pushes played albums to an array
    if a.playcount.to_i >= info[:track_count] - 3 && a.playcount.to_i >=3
      array << {
        :title => a.name,
        :artist => a.artist,
        :track_count => info[:track_count],
        :play_count => a.playcount,
        :url => info[:url],
        :image_url => info[:large_image_url]
      }
    end
  end
  
  # return array as json object
  array.to_json
  
end