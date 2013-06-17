require 'rubygems'
require 'sinatra'
require 'redis'
require 'json'
require 'net/http'
require 'uri'
require 'less'

require_relative 'models/article'

class Siconews < Sinatra::Application
  get '/' do
    erb :index, :locals => { :layout => true }
  end

  get '/css/siconews.css' do
    less :'css/siconews'
  end

  get '/articles/:limit' do
    articles_json_list = Article.get_list(params[:limit], nil, {:format => 'json'})
  end

  # sinatra is annoying about optional path segments
  get '/articles/:limit/:offset' do
    articles_json_list = Article.get_list(params[:limit], params[:offset], {:format => 'json'})
  end

  #mock some initial data from ESPN
  get '/mock' do

    data = fetch_data

    data['headlines'].each do |story|
      photourl = (story['images'][0]) ? story['images'][0]['url'] : 'http://placekitten.com/g/200/300'
      article = Article.new(
        :title=> story['headline'],
        :photo_url => photourl,
        :text => "#{story['description']} Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum ut massa non iaculis. Integer ac augue a dolor aliquam sollicitudin. Nulla ut orci id mi ullamcorper posuere. Nullam eget ultrices mi. Ut tempus, risus vel malesuada porta, felis quam consectetur eros, vitae tempus est ante ut ipsum. Nulla et felis quis quam ultricies dignissim sed in magna. Pellentesque condimentum rutrum nulla quis bibendum. Duis blandit consequat mi sed interdum. Cras vestibulum scelerisque nibh. Maecenas dignissim massa vel tempor feugiat. Nam ligula felis, ultrices ut tempor vel, aliquam ac est. Curabitur sagittis est molestie elit egestas dictum quis ac mauris. Nulla luctus commodo tincidunt. Ut dignissim fermentum elit at congue.
                  Nulla quis nunc purus. Integer varius porttitor placerat. Quisque pretium lectus nulla, vel mollis nulla sodales eget. Ut consectetur, leo eu posuere faucibus, augue ante placerat quam, fringilla tincidunt magna arcu vel velit. Aliquam erat volutpat. Vivamus id vehicula erat. Nunc vitae elit felis. Quisque malesuada interdum quam eget ullamcorper. Nulla tincidunt tincidunt libero, eget adipiscing metus porttitor vel. In non elit porta, tempus lectus eget, varius nisi. Quisque consequat, arcu ut suscipit aliquam, eros lorem mollis libero, eget elementum libero libero aliquet est. Ut pretium pellentesque condimentum. Mauris rhoncus, mauris id tristique imperdiet, mauris sem sagittis diam, sit amet dapibus neque odio quis arcu."
        )
      article.save!
    end

    "data made!"
  end

  private

  def fetch_data

    uri = URI.parse("http://api.espn.com/v1/sports/news/headlines?apikey=#{ENV['ESPN_KEY']}&limit=20")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)

    JSON.parse(response.body)

  end

end