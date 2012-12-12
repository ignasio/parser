module Providers
  class Sbobet < Base
    def initialize(sport)
      super(sport)
  	end

    def bet_lines
      $main = "http://www.sbobet.com"
      url = "http://www.sbobet.com/euro/live-betting"
      agent = Mechanize.new{|a| a.user_agent_alias = 'Windows Mozilla'}
      page = agent.get(url)
      games = page.parser.css('#ms-live a')
      games.each do |game|
        if game.content.split(' ').first==@sport.capitalize.to_s
          send(:extend, "#{self.class.name}::#{@sport.capitalize}".constantize)
          get_sport(game,agent)
        end
      end
    end

  end
end
