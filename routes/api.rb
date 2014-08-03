class Api < Cuba
end

Api.define do
  res.headers["Content-Type"] = "application/json; charset=utf-8"

  on get, "links/:id" do |id|
    link = Link[id]
    res.write(LinkSerializer.new(link).to_json)
  end

  on get, "links", param('q') do |query|
    query = query.downcase

    # Just use in memory search filtering for now
    links = Link.all_for_user(Link::DEFAULT_USER_ID, per_page: 9999)
    links = links.select do |l|
      l.title.downcase.include?(query)
    end

    data = links.map { |l| LinkSerializer.new(l).to_hash }

    res.write({data: data}.to_json)
  end

  on get, "links" do
    if req.params['startkey']
      query = {
        startkey: req.params['startkey'],
        docid: req.params['docid'],
      }
    else
      query = {}
    end

    links = Link.all_for_user(Link::DEFAULT_USER_ID, query)
    serialized_links = LinkCollectionSerializer.new(links)

    res.write serialized_links.to_json
  end

  on post, "links" do
    filter = LinkFilter.new({
      title: req.params["title"],
      url: req.params["url"],
      user_id: Link::DEFAULT_USER_ID,
      tags: req.params["tags"]
    })

    if filter.valid?
      link = Link.create(filter.attributes)
      res.write(LinkSerializer.new(link).to_json)
    else
      res.status = 400
      res.write({status: 'error'}.to_json)
    end
  end

  on put, "links/:id" do |id|
    link = Link[id]

    filter = LinkUpdateFilter.new({
      title: req.params["title"],
      url: req.params["url"],
      tags: req.params["tags"]
    })

    if filter.valid?
      link.update(filter.attributes)
      res.write({status: 'ok'}.to_json)
    else
      res.status = 400
      res.write({status: 'error'}.to_json)
    end
  end

  on delete, "links/:id" do |id|
    link = Link[id]
    link.detach
    res.write({status: 'ok'}.to_json)
  end

end
