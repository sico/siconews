require 'rubygems'
require 'sinatra'
require 'redis'
require 'json'
require 'net/http'
require 'uri'
require 'less'


# REDIS KEYS
#
# global:nextArticleId - integer
# article:<articleid> - hash { title, photo_url, text, created_at }
# articles:all - list<integer>

class Article
  @@redis = @@redis ||= Redis.new
  def initialize(title, photo_url, text)
    @title = title
    @photo_url = photo_url
    @text = text
    @created_at = Time.now
  end


  def self.get_list(limit, offset = 0, options = {})
    #fetch valid ids
    id_list = @@redis.lrange("articles:all", offset, offset.to_i + limit.to_i - 1 )
    articles_list = []
    #pipeline fetch of multiple article futures to prevent network delays
    res = @@redis.pipelined do
      id_list.each do |id|
        articles_list << @@redis.hgetall("article:#{id}")
      end
    end
    #map the futures to Articles
    articles_list.map! do |article|
      Article.new(article.value["title"], article.value["photo_url"], article.value["text"])
    end

    if options[:format] == 'json'
      articles_list.to_json
    else
      articles_list
    end
  end

  def save!
    #get new ID
    article_id = @@redis.incr('global:nextArticleId')
    #save article w new ID as hash (would json string be better since we always access all keys for article?)
    @@redis.mapped_hmset("article:#{article_id}", self.to_a)
    #add article to list
    @@redis.lpush("articles:all", article_id)
  end

  def to_a
    { :title => @title, :photo_url => @photo_url, :text => @text, :created_at => @created_at }
  end

  def to_json(options)
    { "title" => @title, "photo_url" => @photo_url, "text" => @text }.to_json
  end
end


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

  get '/articles/:limit/:offset' do
    articles_json_list = Article.get_list(params[:limit], params[:offset], {:format => 'json'})
  end

  #mock some initial data
  get '/mock' do

    data = fetch_data

    data['stories'].each do |story|
      article = Article.new(
        story['title'],
        'http://placekitten.com/g/200/300',
        "#{story['description']} Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum ut massa non iaculis. Integer ac augue a dolor aliquam sollicitudin. Nulla ut orci id mi ullamcorper posuere. Nullam eget ultrices mi. Ut tempus, risus vel malesuada porta, felis quam consectetur eros, vitae tempus est ante ut ipsum. Nulla et felis quis quam ultricies dignissim sed in magna. Pellentesque condimentum rutrum nulla quis bibendum. Duis blandit consequat mi sed interdum. Cras vestibulum scelerisque nibh. Maecenas dignissim massa vel tempor feugiat. Nam ligula felis, ultrices ut tempor vel, aliquam ac est. Curabitur sagittis est molestie elit egestas dictum quis ac mauris. Nulla luctus commodo tincidunt. Ut dignissim fermentum elit at congue.
                  Nulla quis nunc purus. Integer varius porttitor placerat. Quisque pretium lectus nulla, vel mollis nulla sodales eget. Ut consectetur, leo eu posuere faucibus, augue ante placerat quam, fringilla tincidunt magna arcu vel velit. Aliquam erat volutpat. Vivamus id vehicula erat. Nunc vitae elit felis. Quisque malesuada interdum quam eget ullamcorper. Nulla tincidunt tincidunt libero, eget adipiscing metus porttitor vel. In non elit porta, tempus lectus eget, varius nisi. Quisque consequat, arcu ut suscipit aliquam, eros lorem mollis libero, eget elementum libero libero aliquet est. Ut pretium pellentesque condimentum. Mauris rhoncus, mauris id tristique imperdiet, mauris sem sagittis diam, sit amet dapibus neque odio quis arcu."
        )
      article.save!
    end

    "data made!"
  end

  private

  def find_articles(limit = 3, offset = 0)
    articles = Article.all.sort(:limit => [offset,limit])
    res = []
    articles.each do |article|
      res << article.to_json
    end
    res
  end

  def fetch_data

    uri = URI.parse("http://api.usatoday.com/open/articles/topnews?api_key=#{ENV['USA_TODAY_KEY']}&count=30&encoding=json")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)

    JSON.parse(response.body)

  end

end