namespace :sbobet do
  namespace :import do

    desc 'Imports line lines'
    task live: :environment do
     %w(football).each do |sport|
      provider = Providers::Sbobet.new(sport.to_sym)
      provider.bet_lines
     end  
    end
    
    
  end
end
