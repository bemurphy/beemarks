require "json"

class LinkSerializer
  attr_reader :link

  def initialize(link)
    @link = link
  end

  def to_hash
    {
      id: link.id,
      title: link.title,
      url: link.url,
      host: get_host(link.url),
      created_at: link.created_at.strftime('%-m/%-d/%y'),
      tags: link.tags
    }
  end

  def to_json
    to_hash.to_json
  end

  private

  def get_host(url)
    URI.parse(url.to_s).host
  end
end
