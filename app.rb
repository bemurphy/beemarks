require "cuba"
require "cuba/contrib"
require "mote"
require "rack/protection"
require "scrivener"
require "scrivener_errors"
require "shield"

Cuba.plugin Cuba::Mote
Cuba.plugin Cuba::Prelude
Cuba.plugin ScrivenerErrors::Helpers
Cuba.plugin Shield::Helpers

# Require all application files.
Dir["./models/**/*.rb"].each  { |rb| require rb }
Dir["./serializers/**/*.rb"].each  { |rb| require rb }
Dir["./routes/**/*.rb"].each  { |rb| require rb }

# Require all helper files.
Dir["./helpers/**/*.rb"].each { |rb| require rb }
Dir["./filters/**/*.rb"].each { |rb| require rb }

Cuba.use Rack::MethodOverride
Cuba.use Rack::Session::Cookie,
  key: "beemarks",
  secret: ENV.fetch("SESSION_SECRET")

Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

Cuba.use Rack::ConditionalGet
Cuba.use Rack::ETag

Cuba.use Rack::Static,
  root: "./public",
  urls: %w[/js /css /img /fonts /templates],
  header_rules: [
    # cache 1 week
    [:all, {'Cache-Control' => 'public, max-age=604800'}],
    # 1 year since we use asset signatures
    [%w(css), {'Cache-Control' => 'public, max-age=31536000'}]
  ]

Cuba.define do
  persist_session!

  %w(Content-Security-Policy X-Content-Security-Policy X-WebKit-CSP).each do |header|
    directives = [
      "default-src 'none';",
      # TODO get the unsafe-eval out of here
      "script-src 'self' ajax.googleapis.com 'unsafe-eval';",
      "connect-src 'self';",
      "font-src 'self' themes.googleusercontent.com;",
      "img-src 'self';",
      "style-src 'self' fonts.googleapis.com;"
    ].join(" ")

    unless ENV['SKIP_CSP'] == 'true'
      res.headers[header] = directives
    end
  end

  def escape_data_json(s)
    s.to_s.gsub('/', '\/')
  end

  on "api" do
    run Api
  end

  on root do
    links = Link.all_for_user(Link::DEFAULT_USER_ID)
    serialized_links = LinkCollectionSerializer.new(links)

    render('index', serialized_links: serialized_links)
  end
end
