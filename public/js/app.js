(function(){
  var Link = can.Model.extend({
    resource: "/api/links"
  }, {
    tagsString: can.compute(function(tags) {
      if (arguments.length) {
        this.attr('tags', (tags || '').replace(/\s*,\s*/g, ',').split(','));
      } else {
        return (this.attr('tags') || []).join(',');
      }
    })
  });

  Link.List = Link.List.extend({
    hasNext: function() {
      return this.attr('startkey') !== null;
    },

    replaceWith: function(newLinks) {
      this.replace([]);
      this.replace(newLinks);
      // if (newLinks.next_startkey) {
      //   newLinks.attr('startkey', newLinks.next_startkey && newLinks.next_startkey[1]);
      //   newLinks.attr('startdocid', newLinks.next_startkey_docid);
      // }
    },

    search: function(query, cb) {
      var self = this;
      Link.findAll({q: query}, function(newLinks){
        self.replaceWith(newLinks);
      });
    },

    taggedWith: function(tags, cb) {
      var self = this;
      var url = '/api/tags/' + tags;

      $.get(url).done(function(links){
        self.replaceWith(links.data);
        if (typeof cb === 'function') cb();
      }).fail(function(){
        console.log('an error occurred', arguments);
      });
    },

    next: function(cb) {
      var self = this;

      Link.findAll({startkey: self.attr('startkey'), docid: self.attr('startdocid')}, function(links){
        self.attr('startkey', links.next_startkey && links.next_startkey[1]);
        self.attr('startdocid', links.next_startkey_docid);
        self.push.apply(self, links);
        cb();
      }, function(){
        console.log('error:', arguments);
      });
    }
  });

  var linksData = JSON.parse($('#links-data').text());

  can.Component.extend({
    tag: 'pager',

    scope: {
      isVisible: true,

      next: function() {
        var self = this;

        this.list.next(function(){
          if (!self.list.hasNext()) {
            self.attr('isVisible', false);
          }
        });
      }
    },

    events: {
      '.btn click' : function(el, ev) {
        ev.preventDefault();
        this.scope.next();
      },

      '{list} change': function(el, ev) {
        this.scope.attr('isVisible', can.route.attr('route') === '');
      }
    }
  });

  can.Component.extend({
    tag: 'links',

    scope: {
      searchInput: function(_, el, ev) {
        var enterCode = 13;

        if (ev.keyCode === enterCode) {
          ev.preventDefault();
          this.attr('searching', false);
          window.location.hash = '#!search/' + $(el).val();
        }
      }
    },

    events: {
      'a[data-edit] click': function(el, ev) {
        ev.preventDefault();
        this.scope.editview.edit(el.data('link'));
      },

      'a[data-search] click': function(el, ev) {
        ev.preventDefault();
        this.scope.attr('searching', !this.scope.attr('searching'));
      },

      'a[data-add] click': function(el, ev) {
        ev.preventDefault();
        this.scope.addview.add();
      },

      '#search-input blur': function(el, ev) {
        this.scope.attr('searching', false);
      },

      '{scope} searching': function() {
        if (this.scope.attr('searching')){
          setTimeout(function(){
            $('#search-input').focus();
          }, 0);
        }
      }
    }
  });

  var startKey = linksData.next_startkey && linksData.next_startkey[1];
  var startDocId = linksData.next_startkey_docid;

  var links = new Link.List(linksData.data);
  links.attr('startkey', startKey);
  links.attr('startdocid', startDocId);

  var AddLinkModal = can.Control({
    init: function(el, options) {
      var self = this;

      this.$el = el;
      this.links = options.links;

      this.current = new can.Map({link: null});

      this.modalEl = can.view("//templates/link_modal", {
        save: can.proxy(this.save, this),
        current: this.current,
        modalTitle: 'Add Link',
        domId: 'add-link-modal'
      });

      $('body').on('show.bs.modal', function(){
        self.current.attr('link', new Link());
      });

      $('body').append(this.modalEl);
    },

    save: function(scope, el, ev) {
      ev.preventDefault();

      var link = this.current.attr('link');
      var links = this.links;

      link.save(function(data){
        $('#add-link-modal').modal('hide');
        links.unshift(link);
      });
    },

    add: function() {
      $('#add-link-modal').modal('show');
    },
  });

  var EditLinkModal = can.Control({
    init: function(el, options) {
      this.current = new can.Map({link: null});
      var save = can.proxy(this.save, this);
      this.modalEl = can.view("//templates/link_modal", {
        save: save,
        current: this.current,
        modalTitle: 'Edit Link',
        domId: 'edit-link-modal'
      });

      $('body').append(this.modalEl);

      this.$el = el;
      this.links = options.links;
    },

    save: function(scope, el, ev) {
      ev.preventDefault();

      var editingLink = this.editingLink;

      $('#edit-link-modal').modal('hide');
      editingLink.attr(this.aliasLink.serialize());
      editingLink.attr('tags', this.aliasLink.attr('tags'));

      editingLink.save($.noop, function(){
        console.log('error:', arguments);
      });
    },

    edit: function(link) {
      this.editingLink = link;
      this.aliasLink = new Link(link.serialize());
      this.current.attr('link', this.aliasLink);
      $('#edit-link-modal').modal('show');
    },
  });

  var addLinkModal = new AddLinkModal('#add-link-modal', {
    links: links,
  });

  var editLinkModal = new EditLinkModal('#edit-link-modal', {
    links: links,
  });

  $('#links-wrapper').html(can.view("//templates/links", {
    links: links,
    startkey: linksData.next_startkey && linksData.next_startkey[1],
    startdocid: linksData.next_startkey_docid,
    addview: addLinkModal,
    editview: editLinkModal
  }));

  var Router = can.Control({
    'tags route': function(data) {
      $.get('/api/tags').done(function(data){
        console.log(data);
      }).fail(function(){
        console.log(arguments);
      });
    },

    'tags/:tags route': function(data) {
      links.taggedWith(data.tags);
    },

    'search/:query route': function(data) {
      links.search(data.query, $.noop);
    },

    'route': function() {
      Link.findAll({}, function(newLinks){
        links.replaceWith(newLinks);
      });
    }
  });

  new Router(window);
  can.route.ready();
})();
