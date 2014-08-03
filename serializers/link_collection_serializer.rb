require "json"

class LinkCollectionSerializer
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
    LinkSerializer.new(item).to_hash
  end

  def to_json
    to_hash.to_json
  end
end
