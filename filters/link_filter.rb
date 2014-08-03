class LinkFilter < Scrivener
  attr_accessor :user_id, :title, :url, :tags

  def validate
    assert_present :user_id
    assert_present :title
    assert_present :tags
    assert_url :url
  end
end
