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