namespace :sbobet do
  namespace :import do

    desc 'Imports line lines'
    task live: :environment do
     %w(americanfootball badminton baseball basketball darts football futsal handball hockey rugbyunion snooker soccer tabletennis volleyball waterpolo).each do |sport|
      provider = Providers::Sbobet.new(sport.to_sym)
      provider.bet_lines
     end  
    end
    
    
  end
end
