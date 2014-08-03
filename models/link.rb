require "faker"
require "json"
require "restclient"
require "securerandom"

class User
  attr_accessor :id

  def initialize(id)
    self.id = id
  end
end

class Link
  DEFAULT_USER_ID = 1

  attr_accessor :id
  attr_accessor :title
  attr_accessor :url
  attr_accessor :user_id
  attr_accessor :_rev
  attr_writer :type
  attr_writer :created_at, :updated_at, :detached_at

  class UnixTime < Time
    def to_s
      to_i.to_s
    end
  end

  def tags=(tags)
    if tags.to_s.empty?
      @tags = []
    else
      @tags = tags
    end
  end

  def tags
    @tags || []
  end

  def type
    self.class.name
  end

  def _id=(id)
    self.id = id
  end

  def initialize(atts = {})
    atts.each do |k, v|
      self.send(:"#{k}=", v)
    end
  end

  def created_at
    timecast(@created_at)
  end

  def updated_at
    timecast(@updated_at)
  end

  def detached_at
    timecast(@detached_at)
  end

  def timecast(t)
    t && UnixTime.at(t.to_i)
  end

  def self.database
    "http://localhost:5984/links"
  end

  def self.[](id)
    doc = JSON[RestClient.get(File.join(database, id), content_type: :json)]
    doc["id"] = doc.delete("_id")
    new(doc)
  end

  class Collection
    include Enumerable

    attr_reader :items, :next_startkey, :next_startkey_docid

    def initialize(items = [], next_startkey = nil, next_startkey_docid = nil)
      @items               = items
      @next_startkey       = next_startkey
      @next_startkey_docid = next_startkey_docid
    end

    def <<(item)
      items << item
    end

    def next_item(key, id)
      @next_startkey = key
      @next_startkey_docid = id
    end

    def each(&block)
      items.each { |i| block.call i }
    end
  end

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

    qs = Rack::Utils.build_query(query)
    doc = JSON[RestClient.get(File.join(database, "_design", "links", "_view", "allForUser", "?#{qs}"), content_type: :json)]

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

  def self.create(atts = {})
    new(atts).save
  end

  def delete
    enforce_persisted

    RestClient.delete(File.join(database, id, "?rev=#{_rev}"), content_type: :json)
  end

  def detach
    enforce_persisted

    self.detached_at = Time.now
    save
  end

  def save
    if new_record?
      save_as_new
    else
      save_as_update
    end
  end

  def update(attributes)
    update_attributes(attributes)
    save
  end

  def update_attributes(atts)
    atts.each { |att, val| send(:"#{att}=", val) }
  end

  def new_record?
    !id
  end

  def persisted?
    !new_record?
  end

  def attributes
    Hash.new.tap do |atts|
      atts["type"] = type
      instance_variables.each do |ivar|
        att = ivar[1..-1].to_sym
        atts[att] = send(att)
      end
    end
  end

  def user
    @user ||= User.new(user_id)
  end

  def self.make_fakes(n = 10)
    n.times do
      create(
        title: Faker::Lorem.words(3).join(" ").capitalize,
        url: Faker::Internet.url,
        user_id: DEFAULT_USER_ID,
        tags: Faker::Lorem.words(4).to_a
      )
    end
  end

  private

  def database
    self.class.database
  end

  def enforce_persisted
    persisted? or raise 'Not persisted'
  end

  def save_as_new
    self.created_at = self.updated_at = Time.now.utc
    doc = JSON[RestClient.post(database, attributes.to_json, content_type: :json)]
    self.id = self._id = doc["id"]
    self._rev = doc["rev"]
    self
  end

  def save_as_update
    self.updated_at = Time.now.utc
    doc = JSON[RestClient.put(File.join(database, id), attributes.to_json, content_type: :json)]
    self._rev = doc["rev"]
    self
  end
end
