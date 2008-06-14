# run sinatra apps with ruby <app file>

require File.join(File.dirname(__FILE__), '..', 'lib', 'github-campfire')
require 'sinatra'

post '/' do
  GithubCampfire.new(params[:payload])
  "OMGPONIES! IT WORKED"
end
