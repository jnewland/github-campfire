require 'rubygems'
require 'JSON'
require 'tinder'
require 'sinatra'
require 'erb'

REPOS = YAML.load_file('config.yml')

class GithubCampfire
  
  def initialize(payload)
    payload = JSON.parse(payload)
    return unless payload.keys.include?("repository")
    @repo = payload["repository"]["name"]
    @template = ERB.new(REPOS[@repo]["template"] || "[<%= commit['repo'] %>] <%= commit['message'] %> - <%= commit['author']['name'] %> (<%= commit['url'] %>)")
    @room = connect(@repo)
    payload["commits"].each { |c| process_commit(c.last) }
  end
  
  def connect(repo)
    credentials = REPOS[repo]
    campfire = Tinder::Campfire.new(credentials['subdomain'])
    campfire.login(credentials['username'], credentials['password'])
    return campfire.find_room_by_name(credentials['room'])
  end
  
  def process_commit(commit)
    #we don't need all sorts of local_assigns eval shit here, so this'll do
    commit["repo"] = @repo
    proc = Proc.new do 
      commit
    end
    @room.speak(@template.result(proc))
    speak(@template.result(proc))
  end
  
end

post '/' do
  GithubCampfire.new(params[:payload])
  "OMGPONIES! IT WORKED"
end
