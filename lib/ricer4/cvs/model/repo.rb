module Ricer4::Plugins::Cvs
  class Repo < ActiveRecord::Base
    
    self.table_name = :cvs_repos
    
    abbonementable_by([Ricer4::User, Ricer4::Channel])
    
    belongs_to :user, class_name: 'Ricer4::User'
    
    validates :user, presence:true
    validates :name, named_id:true
    validates :url, uri:{ping:true, trust:false, connect:false, exist:false, schemes: [:ssh, :git, :svn, :http, :https]}
    
    scope :working, -> { where('revision IS NOT NULL') }
    
    arm_install do |m|
      m.create_table table_name do |t|
        t.string  :name,     :null => false, :length => 32
        t.string  :url,      :null => false
        t.string  :system,   :null => true,  :length => 16
        t.integer :user_id,  :null => false
        t.boolean :public,   :null => false
        t.boolean :enabled,  :null => false, :default => 1
        t.string  :username, :null => true
        t.string  :pubkey,   :null => true
        t.string  :password, :null => true
        t.string  :revision, :null => true
        t.timestamps :null => false
      end
      m.add_index table_name, :url,  unique: true
      m.add_index table_name, :name, unique: true
    end
    
    def self.visible(user); self.enabled; end
    def self.enabled; where('cvs_repos.enabled = 1'); end
    def self.deleted; where('cvs_repos.enabled = 0'); end
    
    search_syntax do
      search_by :text do |scope, phrases|
        scope.where_like([:url, :name] => phrases)
      end
      search_by :system do |scope, phrases|
        scope.where(:system => phrases)
      end
#      search_by :user do |scope, phrases|
#      end
    end
    
    def self.by_url(url); where(:url => url).first; end
    def self.by_name(name); where(:name => name).first; end
    def self.by_arg(arg)
      where('id = (?) OR name = (?)', arg, arg).first
    end
    
    def self.allowed_to_read
      joins(:cvs_permissions)
    end
    
    def readable_by?(user)
      return true if self.public
      return true if user == self.user
      return Permission.where(:user => user).where(:repo => self).first != nil
    end
    
    def uri; URI(url); end
    
    ##################
    ### Shell args ###
    ##################
    def url_arg; Shellwords.escape(url); end
    def dir_arg; Shellwords.escape(dir); end
    def name_arg; Shellwords.escape(name); end

    #################
    ### Directory ###
    #################
    def root_dir; "#{Dir.pwd}/files/cvs/repo"; end
    def dir; "#{root_dir}/#{name}"; end

    def cleardir; rmdir && mkdir; end

    def mkdir
      dir = self.dir
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
    end
    
    def rmdir
      dir = self.dir
      FileUtils.remove_dir(dir) if File.directory?(dir)
    end
    
    ###############
    ### Display ###
    ###############
    def display_show_item(num)
      I18n.t 'ricer4.plugins.cvs.msg_show_item', repo_id:self.id, name:self.name, path:self.uri.path, url:self.url
    end
    
    def display_list_item(num)
      I18n.t 'ricer4.plugins.cvs.msg_show_list_item', repo_id:self.id, name:self.name
    end
    
    def revision_url(revision)
      if url.index("github") > 0
        url.trim("/") + "/commit/" + revision
      else
        ""
      end
    end
    
  end
end
