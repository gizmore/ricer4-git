module Ricer4::Plugins::Cvs
  class Cvs < Ricer4::Plugin
    
    trigger_is "git"

    has_files

    has_subcommands

    has_usage
    def execute
      rply(:msg_stats,
        total_repos: Repo.count,
        user_abbos: Repo.abbonements_for(Ricer4::User).count,
        channel_abbos: Repo.abbonements_for(Ricer4::Channel).count,
      )
    end
    
    def plugin_init
      arm_subscribe('ricer/ready') do
        service_threaded do
          loop do
            sleep 30.seconds
            Repo.working.each do |repo|
              sleep 15.seconds
              check_repo repo
            end
          end
        end
      end
    end
    
    def check_repo(repo)
      begin
        bot.log.info("Cvs.check_repo(#{repo.url})")
        system = System.get_system(repo.system).new(repo, self, 10.seconds)
        updates = system.update(10)
        unless updates.empty?
          announce(repo, updates)
          repo.revision = updates[-1].revision
          repo.save!
        end
      rescue StandardError => e
        send_exception(e)
      end
    end
    
    def announce(repo, updates)
      updates.each do |update|
        repo.abbonements.each do |abbonement|
          abbonement.target.localize!.send_privmsg(announce_msg(repo, update))
        end
      end
    end
    
    def announce_msg(repo, update)
      t :msg_announce, repo_name:repo.name, revision:update.display_revision, commiter:update.commiter, comment:update.comment, url: repo.revision_url(update.revision)
    end
    
  end
end
