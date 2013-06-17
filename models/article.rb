# REDIS KEYS
#
# global:nextArticleId - integer
# article:<articleid> - hash { id, title, photo_url, text, created_at }
# articles:all - list<integer>

class Article
  @@redis = @@redis ||= Redis.new

  # not sure of best practice here - named method params or hash?
  def initialize(params)
    @id = params[:id] || @@redis.incr('global:nextArticleId')
    @title = params[:title]
    @photo_url = params[:photo_url]
    @text = params[:text]
    @created_at = params[:created_at] || Time.now
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
      Article.new(:id => article.value["id"], :title => article.value["title"], :photo_url => article.value["photo_url"], :text => article.value["text"])
    end

    if options[:format] == 'json'
      articles_list.to_json
    else
      articles_list
    end
  end

  def save!
    #save article w new ID as hash (would json string be better since we always access all keys for article?)
    @@redis.mapped_hmset("article:#{@id}", self.to_a)
    #add article to list
    @@redis.lpush("articles:all", @id)
  end

  def to_a
    { :id => @id, :title => @title, :photo_url => @photo_url, :text => @text, :created_at => @created_at }
  end

  def to_json(options)
    { "id" => @id, "title" => @title, "photo_url" => @photo_url, "text" => @text }.to_json
  end
end