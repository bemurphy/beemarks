require "nido"
require "redic"

class Tagging
  class Key
    def initialize(user_id)
      @nido = Nido.new('u')[user_id]
    end

    def [](tag)
      @nido[tag]
    end
  end

  def self.redis
    @redic ||= Redic.new
  end

  def self.update(link)
    key = Key.new(link.user_id)

    link.tags_was.each { |tag| redis.queue('SREM', key[tag], link.id) }
    link.tags.each     { |tag| redis.queue('SADD', key[tag], link.id) }
    !!redis.commit
  end

  def self.delete(link)
    key = Key.new(link.user_id)
    link.tags.each { |tag| redis.queue('SREM', key[tag], link.id) }
    !!redis.commit
  end

  def self.links_for(user_id, tags)
    tags = Array(tags)
    key = Key.new(user_id)
    keys = tags.map {|tag| key[tag] }
    ids  = redis.call('SINTER', *keys).sort.reverse

    Link.multi_get ids
  end

  def self.tags_for(user_id)
    url = File.join(Model.database, "_design/links", "_view/byTag", "?group=true")
    data = JSON[RestClient.get(url, content_type: :json)]
    data["rows"].map {|r| { count: r['key'][0], name: r['key'][1] } }
  end
end
