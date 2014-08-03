require_relative "./model"

class Link < Model
  DEFAULT_USER_ID = 1

  attr_accessor :title
  attr_accessor :url
  attr_accessor :user_id
  attr_writer :detached_at

  def self.all_for_user(user_id, query = {})
    per_page = query.fetch(:per_page, 10)

    query[:descending] = true
    query[:limit] = per_page + 1

    # '0' and 'g' are 1 beyond the boundaries of hex values, so
    # they can be used for view keys
    if query[:startkey]
      query[:startkey] = [user_id, query[:startkey]].to_json
    else
      query[:startkey] = [user_id, "g"].to_json
    end

    query[:endkey] = [user_id, "0"].to_json

    qs  = Rack::Utils.build_query(query)
    url = File.join(database, "_design/links", "_view/allForUser", "?#{qs}")
    doc = JSON[RestClient.get(url, content_type: :json)]

    collection = Collection.new

    per_page.times.each do |idx|
      if row = doc["rows"][idx]
        collection << new(row["value"])
      end
    end

    if next_item = doc["rows"][per_page]
      collection.next_item(next_item["key"], next_item["id"])
    end

    collection
  end

  def tags=(tags)
    if tags.to_s.empty?
      @tags = []
    else
      @tags = tags.uniq
    end
  end

  def tags
    @tags || []
  end

  def detached_at
    timecast(@detached_at)
  end

  def detach
    enforce_persisted

    self.detached_at = Time.now
    save
  end
end
