module Ricer4::Plugins::Cvs
  class Add < Ricer4::Plugin
    
    trigger_is "cvs add"
    permission_is :voice
    
    denial_of_service_protected

    has_setting name: :default_public, type: :boolean, scope: :bot,     permission: :responsible, default:false
    has_setting name: :default_delay,  type: :integer, scope: :user,    permission: :operator,    default:60, min:3, max:240
    has_setting name: :default_delay,  type: :integer, scope: :channel, permission: :operator,    default:60, min:3, max:240
    
    has_usage  '<name> <url>', function: :execute
    has_usage  '<name> <url> <boolean>', function: :execute_b
    has_usage  '<name> <url> <boolean> <pubkey>', function: :execute_bp
    def execute(name, url); execute_b(name, url, get_setting(:default_public)); end
    def execute_b(name, url, public); execute_bp(name, url, public, nil); end
    def execute_bp(name, url, public, pubkey)
      
      return rply :err_dup_name unless Repo.by_name(name).nil?
      return rply :err_dup_url unless Repo.by_url(url).nil?
      
      repo = Repo.new({
        user: user,
        name: name,
        url: url,
        public: public,
        pubkey: pubkey,
      })
      repo.validate!
      threaded do
        execute_csv_add(repo, name, url, public, pubkey)
      end
    end
    
    def execute_csv_add(repo, name, url, public, pubkey)
      system = System.new(repo, self, setting(:default_delay))
      system_name = system.detect
      return rply :err_system if system_name.nil?
      system = System.get_system(system_name).new(repo, self, setting(:default_delay))
      return rply :err_system if system.nil?
      repo.system = system_name
      repo.revision = system.revision
      repo.save!
      rply :msg_repo_added, name:repo.name, url:repo.url, type:repo.system
    end
    
  end
end
