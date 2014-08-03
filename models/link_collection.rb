class Link
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
end
