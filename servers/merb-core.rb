# run very flat apps with merb -I <app file>.

require File.join(File.dirname(__FILE__), '..', 'lib', 'github-campfire')

Merb::Router.prepare do |r|
  r.match('/', :method => 'POST').to(:controller => 'campfire', :action =>'index')
end

class Campfire < Merb::Controller
  def index
    GithubCampfire.new(params[:payload])
    "OMGPONIES! IT WORKED"
  end
end

Merb::Config.use { |c|
  c[:framework]           = {:public => "public"},
  c[:session_store]       = 'none',
  c[:exception_details]   = true
}
