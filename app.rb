require 'rubygems'
require 'bundler'
Bundler.setup

require 'sinatra'
require 'rockstar'

# initialise api key
Rockstar.lastfm = YAML.load_file('lastfm.yml')
set :haml, :format => :html5

get '/' do
  if params[:user] == 'error'
    @error = true
  end
  
  haml(:index)
end

  
get '/albums' do
  headers['Cache-Control'] = 'public, max-age=172800' # Cache for two days
  
  @user = params[:user]
  
  begin
    user = Rockstar::User.new(@user)
    @rss = "http://lastlp.heroku.com/rss/#{@user}"
  rescue
    redirect to '/?user=error'  # in case the ID is not recognised
  end
  
  # get albums
  array = []
  user.weekly_album_chart[0..9].each do |a|
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
  
  # return array
  @albums = array
  
  haml(:albums)
end

get '/rss/*' do
  content_type 'application/rss+xml', :charset => 'utf-8'
  headers['Cache-Control'] = 'public, max-age=172800' # Cache for two days
  
  @user = params["splat"].first
  
  begin
    user = Rockstar::User.new(@user)
  rescue
    redirect to '/?user=error'  # in case the ID is not recognised
  end
  
  # get albums
  array = []
  user.weekly_album_chart[0..9].each do |a|
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
  
  # return array in reverse order, so RSS appears in right order chronologically
  @albums = array.reverse
  
  haml(:rss, :format => :xhtml, :layout => false)
end

get '/style.css' do
  sass :style
end