module Ricer4::Plugins::Cvs
  class List < Ricer4::Plugin
    
    is_list_trigger :list, :for => Ricer4::Plugins::Cvs::Repo
    
  end
end
