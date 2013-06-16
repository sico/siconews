require 'rubygems'
require 'sinatra'
require 'ohm'
require 'json'
require 'net/http'
require 'uri'
require 'less'


class Article < Ohm::Model
  attribute :title
  attribute :photo_url
  attribute :text

  def to_json
    { :title => self.title, :photo_url => self.photo_url, :text => self.text }
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
    articles_json_list = find_articles(params[:limit])
    articles_json_list.to_json
  end

  get '/articles/:limit/:offset' do
    articles_json_list = find_articles(params[:limit], params[:offset])
    articles_json_list.to_json
  end

  #mock some initial data
  get '/mock' do

    data = fetch_data

    data['stories'].each do |story|
      article = Article.create(
        :title => story['title'],
        :photo_url => 'http://placekitten.com/g/200/300',
        :text => "#{story['description']} Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum ut massa non iaculis. Integer ac augue a dolor aliquam sollicitudin. Nulla ut orci id mi ullamcorper posuere. Nullam eget ultrices mi. Ut tempus, risus vel malesuada porta, felis quam consectetur eros, vitae tempus est ante ut ipsum. Nulla et felis quis quam ultricies dignissim sed in magna. Pellentesque condimentum rutrum nulla quis bibendum. Duis blandit consequat mi sed interdum. Cras vestibulum scelerisque nibh. Maecenas dignissim massa vel tempor feugiat. Nam ligula felis, ultrices ut tempor vel, aliquam ac est. Curabitur sagittis est molestie elit egestas dictum quis ac mauris. Nulla luctus commodo tincidunt. Ut dignissim fermentum elit at congue.
                  Nulla quis nunc purus. Integer varius porttitor placerat. Quisque pretium lectus nulla, vel mollis nulla sodales eget. Ut consectetur, leo eu posuere faucibus, augue ante placerat quam, fringilla tincidunt magna arcu vel velit. Aliquam erat volutpat. Vivamus id vehicula erat. Nunc vitae elit felis. Quisque malesuada interdum quam eget ullamcorper. Nulla tincidunt tincidunt libero, eget adipiscing metus porttitor vel. In non elit porta, tempus lectus eget, varius nisi. Quisque consequat, arcu ut suscipit aliquam, eros lorem mollis libero, eget elementum libero libero aliquet est. Ut pretium pellentesque condimentum. Mauris rhoncus, mauris id tristique imperdiet, mauris sem sagittis diam, sit amet dapibus neque odio quis arcu."
        )
      article.save
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

    uri = URI.parse("http://api.usatoday.com/open/articles/topnews?api_key=xekehgwbktj33vpssutmb9y2&count=30&encoding=json")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)

    JSON.parse(response.body)

  end

end