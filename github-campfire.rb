require 'rubygems'
require 'json'
require 'tinder'
require 'sinatra'
require 'erb'

REPOS = YAML.load_file('config.yml')

class GithubCampfire
  attr_reader :repo
  
  DEFAULT_TEMPLATE = "[<%= commit['repo'] %>] <%= commit['message'] %> - <%= commit['author']['name'] %> (<%= commit['url'] %>)".freeze
  
  def initialize(payload=nil)
    process_payload(payload) if payload
  end
  
  def process_payload(payload)
    payload = JSON.parse(payload)
    return unless payload.keys.include?("repository")
    @repo = payload["repository"]["name"]
    
    @room = connect(@repo)
    payload["commits"].each { |c| process_commit(c.last) }
  end
  
  def credentials
    @credentials ||= REPOS[@repo]
  end
  
  def template
    @template ||= template_for(credentials['template'])
  end
  
  def template_for(raw)
    case raw
    when String
      template_for(:speak => raw)
    when Array
      raw.map { |l| template_for(l) }.flatten
    when Hash
      method, content = Array(raw).first
      {method => content.is_a?(String) ? ERB.new(content) : content}
    when nil, ''
      template(DEFAULT_TEMPLATE)
    else
      raise ArgumentError, "Invalid template #{raw.inspect}"
    end
  end
  
  def connect(repo)
    credentials = REPOS[repo]
    
    # generate Tinder options
    options = {}
    options[:ssl] = credentials['ssl'] || false
    options[:proxy] = credentials['proxy'] || ENV[options[:ssl] ? 'https_proxy' : 'http_proxy']
    
    campfire = Tinder::Campfire.new(credentials['subdomain'], options)
    campfire.login(credentials['username'], credentials['password'])
    return campfire.find_room_by_name(credentials['room'])
  end
  
  def process_commit(commit)
    #we don't need all sorts of local_assigns eval shit here, so this'll do
    commit["repo"] = @repo
    proc = Proc.new do 
      commit
    end
    template.each do |action|
      method, content = Array(action).first
      @room.send(method, content.result(proc), :join => false)
    end
  end
  
end

post '/' do
  GithubCampfire.new(params[:payload])
  "OMGPONIES! IT WORKED"
end