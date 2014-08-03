class LinkUpdateFilter < Scrivener
  attr_accessor :title, :url, :tags

  def validate
    assert_present :title
    assert_present :tags
    assert_url :url
  end
end
