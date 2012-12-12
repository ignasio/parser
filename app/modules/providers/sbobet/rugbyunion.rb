module Providers
  class Sbobet < Base
    module Rugbyunion
        
        def get_line(league,agent)
          page = agent.get($main+league['href'])
          du = page.content.scan(/(\d{7},(.*))/)[0][0]
          home_t = du.split(',')[1].downcase.delete("'").gsub(/ /,'-')
          away_t = du.split(',')[2].downcase.delete("'").gsub(/ /,'-')
          url = $main+league['href']+"/"+du.split(',')[0]+"/"+home_t+"-vs-"+away_t
          page = agent.get(url)
          str = page.at("//script[contains(.,'function initiateOddsDisplay()')]").content
          data = str.scan(/onUpdate\('od',(.*)\);\$/)
          data[0][0] = data[0][0].gsub(/,,\{(.*)\}/,'')
          data[0][0] = data[0][0].gsub(/,\{(.*)\}/,'')
          data[0][0].gsub!(/'/,'"')
          #puts data[0][0] 
          #puts league.content.gsub!(/\(\d\)|\d/,'')
          teams = home_t+"-"+away_t
          league = league.content.gsub!(/\(\d\)|\d/,'').strip
          arr={"Rugbyunion"=>{league=>{teams=>[]}}}
          data = JSON.parse(data[0][0])
          count =0
          count = data[2][0][1][0][3].length.to_i-1 if data[2][0][1][0] and data[2][0][1][0][3]
          unless data.nil?  
            count.times do |i|
              #puts data[2][0][1][0][3][i+1][2]
              #puts data[2][0][1][0][3][i+1][1][0]
              case data[2][0][1][0][3][i+1][1][0]
              when 1 then
                #puts "ah"
                #puts "0, F1, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][0]}"
                #puts "0, F2, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][1]}"
                arr["Rugbyunion"][league][teams].push([0,"F1",data[2][0][1][0][3][i+1][1][5],data[2][0][1][0][3][i+1][2][0]])
                arr["Rugbyunion"][league][teams].push([0,"F2",data[2][0][1][0][3][i+1][1][5],data[2][0][1][0][3][i+1][2][1]])
              when 7 then
                #puts "fhah"
                #puts "0, F1, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][0]}"
                #puts "0, F2, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][1]}"
                arr["Rugbyunion"][league][teams].push([0,"F1",data[2][0][1][0][3][i+1][1][5],data[2][0][1][0][3][i+1][2][0]])
                arr["Rugbyunion"][league][teams].push([0,"F2",data[2][0][1][0][3][i+1][1][5],data[2][0][1][0][3][i+1][2][1]])
              when 8 then
                #puts "1st"
                #puts "0, 1, nil, #{data[2][0][1][0][3][i+1][2][0]}"
                #puts "0, x, nil, #{data[2][0][1][0][3][i+1][2][1]}"
                #puts "0, 2, nil, #{data[2][0][1][0][3][i+1][2][2]}"
                arr["Rugbyunion"][league][teams].push([0,"1",nil,data[2][0][1][0][3][i+1][2][0]])
                arr["Rugbyunion"][league][teams].push([0,"X",nil,data[2][0][1][0][3][i+1][2][1]])
                arr["Rugbyunion"][league][teams].push([0,"2",nil,data[2][0][1][0][3][i+1][2][2]])

              when 9 then
                #puts "fhou"
                #puts "0, TO, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][0]}"
                #puts "0, TU, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][1]}"
                arr["Rugbyunion"][league][teams].push([0,"TO",data[2][0][1][0][3][i+1][1][5],data[2][0][1][0][3][i+1][2][0]])
                arr["Rugbyunion"][league][teams].push([0,"TU",data[2][0][1][0][3][i+1][1][5],data[2][0][1][0][3][i+1][2][1]])
              when 3 then
                #puts "totals"
                #puts "0, TO, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][0]}"
                #puts "0, TU, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][1]}"
                arr["Rugbyunion"][league][teams].push([0,"TO",data[2][0][1][0][3][i+1][1][5],data[2][0][1][0][3][i+1][2][0]])
                arr["Rugbyunion"][league][teams].push([0,"TU",data[2][0][1][0][3][i+1][1][5],data[2][0][1][0][3][i+1][2][1]])
              when 5 then
                #puts "1x2"
                #puts "0, 1, nil, #{data[2][0][1][0][3][i+1][2][0]}"
                #puts "0, x, nil, #{data[2][0][1][0][3][i+1][2][1]}"
                #puts "0, 2, nil, #{data[2][0][1][0][3][i+1][2][2]}"
                arr["Rugbyunion"][league][teams].push([0,"1",nil,data[2][0][1][0][3][i+1][2][0]])
                arr["Rugbyunion"][league][teams].push([0,"X",nil,data[2][0][1][0][3][i+1][2][1]])
                arr["Rugbyunion"][league][teams].push([0,"2",nil,data[2][0][1][0][3][i+1][2][2]])
              else
                puts "ADD ME TO CASE"
                puts "0, TO, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][0]}"
                puts "0, TU, #{data[2][0][1][0][3][i+1][1][5]}, #{data[2][0][1][0][3][i+1][2][1]}"
              end
            end
          end
          puts arr
        end

        def get_league(country,agent)
          page = agent.get($main+country['href'])
          leagues = page.parser.css('ul#ms-live li.Sel div a')
          leagues.each do |league|
            get_line(league,agent)
          end
        end

        def get_sport(game,agent)
          page = agent.get($main+game['href'])
          countries = page.parser.css('li.SptSel').last
          countries.children().last.children().css('a').each do |country|
            get_league(country,agent)
          end
        end

    end
  end
end
