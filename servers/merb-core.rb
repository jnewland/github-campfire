# run very flat apps with merb -I <app file>.

require File.join(File.dirname(__FILE__), '..', 'lib', 'github-campfire')

Merb::Router.prepare do |r|
  r.match('/', :method => :post).to(:controller => 'campfire', :action =>'index')
end

class Campfire < Merb::Controller
  def index
    begin
      GithubCampfire.new(params[:payload])
      "OMGPONIES! IT WORKED"
    rescue => e
      self.status = 500
      return "An exception has occurred posting the payload to Campfire:\n" +
             "  #{e.message}\n" + 
             e.backtrace.map {|frame| "  #{frame}"}.join("\n")
    end
  end
end

Merb::Config.use { |c|
  c[:framework]           = {:public => "public"},
  c[:session_store]       = 'none',
  c[:exception_details]   = true
}
