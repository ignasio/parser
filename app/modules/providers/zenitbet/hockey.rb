# encoding: UTF-8
module Providers
  class Zenitbet < Base
    module Hockey

      def parse(page)
        page.search("div.b-league[id^=lid]").each do |league_node|
          title_node = league_node.at('div.b-league-name span.b-league-name-label')
          sport_name, league_name = title_node.content.split(/\.\s*/, 2)

          league_identifier = league_node.at("div.b-league-name.h-league")["data-lid"]

          # try to find bookmaker sport
          next unless (bookmaker_sport.name == sport_name)
          next if league_name =~ /Статистические данные|goals|special|extra bets|all\-stars weekend/i

          # try to find or create bookmaker league
          @bookmaker_league = create_bookmaker_league(league_name, league_identifier)
          @bookmaker_events = bookmaker_events(@bookmaker_league)

          league_node.search('tr[id^=gid]').each do |event_node|
            event_id = event_node.attr("id").gsub(/gid/, "")
            next if event_id =~ /ross/

            # KHL and NHL - with OT
            period = league_name =~ /КХЛ|НХЛ/ ? -1 : 0

            basic_line = event_node.search('./td').map{ |node| node.content.gsub(/,/, '.').strip }
            event_raw_date, teams, _1, _x, _2, _1x, _12, _x2, hand_1, odds_1, hand_2, odds_2, under, total, over = basic_line
            #puts basic_line.join(' : ')

            team_1, team_2 = teams.split(' - ', 2)
            team_2.gsub!(/ Нейтральное поле/, "")

            next unless (team_1 and team_2)

            # check teams first
            home_team = create_bookmaker_team(team_1)
            away_team = create_bookmaker_team(team_2)

            # creating events
            Time.zone = @time_zone
            event_time = Time.strptime("#{event_raw_date}", '%d/%m %H:%M').strftime("%Y-%m-%d %H:%M")
            event_time = Time.zone.parse("#{event_time}")
            bookmaker_event = create_bookmaker_event(home_team, away_team, event_time)



            # bookmaker's bet
            @bets = bookmaker_event.bets
            @bets_to_remove[bookmaker_event.id] = @bets.map(&:id) unless @bets_to_remove[bookmaker_event.id]

            # basic line
            # handicap 1
            create_or_update_bet(bookmaker_event, period, 'F1', hand_1, odds_1)
            # handicap 2
            create_or_update_bet(bookmaker_event, period, 'F2', hand_2, odds_2)
            # first team win
            create_or_update_bet(bookmaker_event, period, '1', nil, _1)
            # draw
            create_or_update_bet(bookmaker_event, period, 'X', nil, _x)
            # second team win
            create_or_update_bet(bookmaker_event, period, '2', nil, _2)
            # first team double chance
            create_or_update_bet(bookmaker_event, period, '1X', nil, _1x)
            # first or second double chance
            create_or_update_bet(bookmaker_event, period, '12', nil, _12)
            # second team double chance
            create_or_update_bet(bookmaker_event, period, 'X2', nil, _x2)
            # totals
            create_or_update_bet(bookmaker_event, period, 'TO', total, over)
            create_or_update_bet(bookmaker_event, period, 'TU', total, under)

            add_lines_node = league_node.at("tr[@id=gid-ross#{event_id}]")
            if add_lines_node
              add_lines_node.search("td div div").each do |line|

                # spreads
                if line.content =~ /Дополнительные форы:/
                  team_1_spreads, team_2_spreads = line.content.gsub(/Дополнительные форы: #{team_1}: фора матча/, "").split("#{team_2}: фора матча ").map(&:strip)
                   team_1_spreads.split("; ").each do |spread|
                    m = spread.match(/\(([\d\.\-\,]+)\) - ([\d\.\,]+)/)
                    create_or_update_bet(bookmaker_event, period, "F1", m[1], m[2].gsub(/,/, '.')) if m
                   end
                  team_2_spreads.split("; ").each do |spread|
                    m = spread.match(/\(([\d\.\-\,]+)\) - ([\d\.\,]+)/)
                    create_or_update_bet(bookmaker_event, period, "F2", m[1], m[2].gsub(/,/, '.')) if m
                   end
                end

                # totals
                if line.content =~ /Дополнительные тоталы:/
                  unders, overs = line.content.gsub(/Дополнительные тоталы: меньше/, "").split("больше").map(&:strip)
                  unders.split("; ").each do |total_under|
                    m = total_under.match(/\(([\d\.\,]+)\) - ([\d\.\,]+)/)
                    create_or_update_bet(bookmaker_event, period, "TU", m[1], m[2].gsub(/,/, '.')) if m
                  end
                  overs.split("; ").each do |total_over|
                    m = total_over.match(/\(([\d\.\,]+)\) - ([\d\.\,]+)/)
                    create_or_update_bet(bookmaker_event, period, "TO", m[1], m[2].gsub(/,/, '.')) if m
                  end
                end

                # ind totals
                [team_1, team_2].each_with_index do |team, i|
                  if line.content =~ /Индивидуальные тоталы: #{team} меньше/
                    unders, overs = line.content.gsub(/Индивидуальные тоталы: #{team} Меньше/, "").split("больше").map(&:strip)
                    unders.split("; ").each do |total_under|
                      m = total_under.match(/\(([\d\.\,]+)\) - ([\d\.\,]+)/)
                      create_or_update_bet(bookmaker_event, period, "I#{i+1}TU", m[1], m[2].gsub(/,/, '.')) if m
                    end
                    overs.split("; ").each do |total_over|
                      m = total_over.match(/\(([\d\.\,]+)\) - ([\d\.\,]+)/)
                      create_or_update_bet(bookmaker_event, period, "I#{i+1}TO", m[1], m[2].gsub(/,/, '.')) if m
                    end
                  end
                end

                # period totals
                %w(1 2 3).each do |period|
                  if line.content =~ /Дополнительные тоталы #{period}-го периода/
                    unders, overs = line.content.gsub(/Дополнительные тоталы #{period}-го периода: меньше/, "").split("больше").map(&:strip)
                    unders.split("; ").each do |total_under|
                      m = total_under.match(/\(([\d\.\,]+)\) - ([\d\.\,]+)/)
                      create_or_update_bet(bookmaker_event, period.to_i, "TU", m[1], m[2].gsub(/,/, '.')) if m
                    end
                    overs.split("; ").each do |total_over|
                      m = total_over.match(/\(([\d\.\,]+)\) - ([\d\.\,]+)/)
                      create_or_update_bet(bookmaker_event, period.to_i, "TO", m[1], m[2].gsub(/,/, '.')) if m
                    end
                  end
                end

                # both to score, ind.to score
                if line.content =~ /Голы: /
                  parts = line.content.gsub(/Голы: /, "").split("; ").map(&:strip)
                  parts.each do |part|
                    [team_1, team_2].each_with_index do |team, i|
                      team_score = part.match(/#{team} забьёт \- ([\d\.\,]+), не забьёт \- ([\d\.\,]+)/)
                      if team_score
                        create_or_update_bet(bookmaker_event, period, "I#{i+1}TO", 0.5, team_score[1].gsub(/,/, '.')) if team_score[1]
                        create_or_update_bet(bookmaker_event, period, "I#{i+1}TU", 0.5, team_score[2].gsub(/,/, '.')) if team_score[2]
                      end
                    end
                    bts_y = part.match(/обе забьют - ([\d\.\,]+)/)
                    create_or_update_bet(bookmaker_event, period, 'BTS_Y', nil, bts_y[1].gsub(/,/, '.')) if bts_y

                    bts_n = part.match(/хотя бы одна не забьёт - ([\d\.\,]+)/)
                    create_or_update_bet(bookmaker_event, period, 'BTS_N', nil, bts_n[1].gsub(/,/, '.')) if bts_n

                    total_score = part.match(/нет голов - ([\d\.\,]+)/)
                    create_or_update_bet(bookmaker_event, period, 'TU', 0.5, total_score[1].gsub(/,/, '.')) if total_score
                  end
                end

                # even/odd
                if line.content =~ /Чёт\/Нечёт: /
                  event_odd_matches = line.content.match(/Чёт\/Нечёт: чётный тотал матча \-\s([\d\.\,]+),\s+нечётный тотал матча\s\-\s([\d\.\,]+);/)
                  even_value, odd_value = event_odd_matches ? [event_odd_matches[1].gsub(/,/, '.'), event_odd_matches[2].gsub(/,/, '.')] : [nil, nil]
                  create_or_update_bet(bookmaker_event, period, 'EVEN', nil, even_value) if even_value
                  create_or_update_bet(bookmaker_event, period, 'ODD', nil, odd_value) if odd_value
                end
              end

              # halves outcome
              if (halves_outcome_node = add_lines_node.at('table'))

                halves_outcome_node.search("tr").each do |tr|
                  _line = tr.search('./td').map{ |node| node.content.gsub(/,/, '.').strip }
                  next unless _line.size > 0
                  case _line.size
                    when 11 #  # П1	Х	П2	Ф1	Кф1	Ф2	Кф2	Мен	Тот	Бол
                      period, _1, _x, _2, hand_1, odds_1, hand_2, odds_2, under_1, total_1, over_1 = _line
                    when 7 #  # П1	Х	П2	Мен	Тот	Бол
                      period, _1, _x, _2, under_1, total_1, over_1 = _line
                    else
                      period, hand_1, odds_1, hand_2, odds_2, under_1, total_1, over_1 = _line
                  end
                  period.gsub!(/\D/, "")

                  if _line.size == 11 or _line.size == 7
                    # first team win
                    create_or_update_bet(bookmaker_event, period, '1', nil, _1)
                    # draw
                    create_or_update_bet(bookmaker_event, period, 'X', nil, _x)
                    # second team win
                    create_or_update_bet(bookmaker_event, period, '2', nil, _2)
                  end
                  # handicap 1
                  create_or_update_bet(bookmaker_event, period, 'F1', hand_1, odds_1)
                  # handicap 2
                  create_or_update_bet(bookmaker_event, period, 'F2', hand_2, odds_2)
                  # totals
                  if total_1
                    create_or_update_bet(bookmaker_event, period, 'TO', total_1, over_1)
                    create_or_update_bet(bookmaker_event, period, 'TU', total_1, under_1)
                  end
                end
              end
            end
            rescan_event(bookmaker_event)
          end
        end
      end
    end
  end
end