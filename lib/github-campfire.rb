require 'rubygems'
require 'json'
require 'tinder'
require 'erb'

class GithubCampfire
  attr_reader :repo
  
  DEFAULT_TEMPLATE = "[<%= commit['repo'] %>] <%= commit['message'] %> - <%= commit['author']['name'] %> (<%= commit['url'] %>)".freeze
  
  def initialize(payload=nil)
    @repos = YAML.load_file(ENV['CONFIG'] || 'config.yml')
    process_payload(payload) if payload
  end
  
  def process_payload(payload)
    payload = JSON.parse(payload)
    return unless payload.keys.include?("repository")
    @repo = payload["repository"]["name"]
    
    @room = connect(@repo)
    payload["commits"].sort_by { |id,c| c["timestamp"] }.each { |id,c| process_commit(c) }
  end
  
  def settings(repo=@repo)
    case s = @repos[repo.to_s]
    when Hash
      return s
    when String, Symbol
      return settings(s)
    else
      raise "No settings found for repo=#{repo.inspect}" if repo.to_s == 'default'
      return settings(:default)
    end
  end
  
  def template
    @template ||= template_for(settings['template'])
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
    # generate Tinder options
    options = {}
    options[:ssl] = settings['ssl'] || false
    options[:proxy] = settings['proxy'] || ENV[options[:ssl] ? 'https_proxy' : 'http_proxy']
    
    campfire = Tinder::Campfire.new(settings['subdomain'], options)
    campfire.login(settings['username'], settings['password'])
    return campfire.find_room_by_name(settings['room'])
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
