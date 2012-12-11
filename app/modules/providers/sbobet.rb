module Providers
  class Sbobet < Base
    
    def bet_lines
      $main = "http://www.sbobet.com"
      url = "http://www.sbobet.com/euro/live-betting"
      agent = Mechanize.new{|a| a.user_agent_alias = 'Windows Mozilla'}
      page = agent.get(url)
      games = page.parser.css('#ms-live a')
      games.each do |game|
      #puts game.content.split(' ').first
        if game.content.split(' ').first=='Basketball' or game.content.split(' ').first=='Volleyball' or game.content.split(' ').first=='Football'
          send(:extend, "#{self.class.name}::#{game.content.split(' ').first.capitalize}".constantize)
          #"#{game.content.split(' ').first.capitalize}".constantize.
          get_sport(game,agent)
        end
      end
    end

  end
end
