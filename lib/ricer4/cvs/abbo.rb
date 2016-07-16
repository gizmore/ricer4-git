module Ricer4::Plugins::Cvs
  class Abbo < Ricer4::Plugin
    
    is_add_abbo_trigger :for => Ricer4::Plugins::Cvs::Repo

    def abbo_find(relation, term)
      relation.where(:name => term).first ||
      relation.find(term)
    end

  end
end
