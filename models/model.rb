require "json"
require "restclient"

class Model
  attr_accessor :id
  attr_accessor :_rev

  attr_writer :type
  attr_writer :created_at, :updated_at

  def self.database
    "http://localhost:5984/links"
  end

  def self.[](id)
    doc = JSON[RestClient.get(File.join(database, id), content_type: :json)]
    doc["id"] = doc.delete("_id")
    new(doc)
  end

  def self.create(atts = {})
    new(atts).save
  end

  def initialize(atts = {})
    atts.each do |k, v|
      self.send(:"#{k}=", v)
    end
  end

  def type
    self.class.name
  end

  def _id=(id)
    self.id = id
  end

  def created_at
    timecast(@created_at)
  end

  def updated_at
    timecast(@updated_at)
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

  def delete
    enforce_persisted

    RestClient.delete(File.join(database, id, "?rev=#{_rev}"), content_type: :json)
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

  private

  def database
    self.class.database
  end

  def enforce_persisted
    persisted? or raise 'Not persisted'
  end

  class UnixTime < Time
    def to_s
      to_i.to_s
    end
  end

  def timecast(t)
    t && UnixTime.at(t.to_i)
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
