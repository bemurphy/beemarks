require "json"

class LinkCollectionSerializer < JsonSerializer
  def initialize(collection)
    @collection = collection
  end

  def to_hash
    {
      next_startkey: @collection.next_startkey,
      next_startkey_docid: @collection.next_startkey_docid,
      data: @collection.map { |item| serialize(item) }
    }
  end

  def serialize(item)
    {
      id: item.id,
      title: item.title,
      url: item.url,
      host: get_host(item.url),
      created_at: item.created_at.strftime('%-m/%-d/%y'),
      tags: item.tags
    }
  end

  def get_host(url)
    URI.parse(url.to_s).host
  end

  def to_json
    to_hash.to_json
  end
end
