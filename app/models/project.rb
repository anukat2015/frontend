# require 'backend'

class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  field :vcs_url
  field :ssh_private_key
  field :ssh_public_key

  has_and_belongs_to_many :users
#  has_many :builds
  has_many :specs

  attr_accessible :vcs_url

  def to_param
    github_project_name
  end

  def self.from_url(url)
    projects = Project.where(:vcs_url => url)
    projects.first
  end

  def self.from_github_name(name)
    url = Backend.blocking_worker "circle.backend.github-url/canonical-url", name
    self.from_url(url)
  end

  # TECHNICAL_DEBT: projects should have a list of builds, but it doesnt on the clojure side.
  def recent_builds(limit=10)
    Build.where(:vcs_url => vcs_url).order_by([[:build_num, :desc]]).limit(limit)
  end

  def latest_build
    Build.where(:vcs_url => vcs_url).order_by([[:build_num, :desc]]).limit(1).first
  end

  def build_numbered(num) # bad things happen if we call this "build"
    Build.where(:vcs_url => vcs_url, :build_num => num).first
  end

  def github_project_name
    result = vcs_url.sub("https://github.com/", "")
    if result[-1] == "/" then
      result = result[0..-2]
    end
    result
  end

  def config
    # For now, just read circle.yml for everyone, and see what happens.
    File.read("#{File.dirname(__FILE__)}/../../circle.yml")
  end
end
