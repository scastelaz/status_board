class Board < ActiveRecord::Base

	has_many :cards

	require 'trello'
  APP_TRELLO = YAML.load_file(Rails.root.to_s + '/config/trello.yml')

  Trello.configure do |config|
    config.developer_public_key = APP_TRELLO["app_key"]
    config.member_token = APP_TRELLO["guest_key"]
  end

  def self.trello_info
  	puts "Percent of cards in 'Development In Progress':"
  	Board.all.each do|board|
  	 	puts "\t#{board.name}"
  	 	puts "\t\t#{trello_card_count_in_dev(board.url_id)}"
  	end
  	puts "Percent of cards past 'Development In Progress':"
  	Board.all.each do|board|
  		puts "\t#{board.name}"
  	 	puts "\t\t#{trello_card_count_past_dev(board.url_id)}"
  	end
  	puts "Number of cards with a 'Bug' label:"
  	Board.all.each do|board|
  	 	puts "\t#{board.name}"
  	 	puts "\t\t#{find_trello_bug_cards(board.url_id)}"
  	end
  	puts "Time for cards from 'Up Next' to 'Last Production':"
  	Board.all.each do|board|
  		puts "\t#{board.name}"
  		get_cards_from_trello(board.url_id)
  		ary = time_to_production(board)
  		if ary != nil
  			ary.each do |card|
  				puts "\t\t#{card}"
  			end
  		end
  	end
  	return nil
  end

	def self.get_cards_from_trello(board)
		card_list = Trello::Board.find(board).cards.to_s
		cards = find_trello_card_ids(card_list)
		cards.each do |card|
			temp = Trello::Card.find(card)
			if temp.list.name == "Up Next" || temp.list.name == "UP NEXT"
				if Card.find_by_name(temp.name) == nil && (idBoard = Board.find_by_url_id(board)) != nil
					info = Card.create(:enterDate => temp.last_activity_date, :boardable_id => idBoard.id, :name => temp.name)
					info.save
				end
			elsif temp.list.name == "Last Production" || temp.list.name == "LAST PRODUCTION"
				if (check = Card.find_by_name(temp.name)) != nil && check.leaveDate == nil
					info = Card.find_by_name(temp.name)
					info.update(:leaveDate => temp.last_activity_date)
					info.save
				end
			end
		end
		return nil
	end

	def self.time_to_production(board)
		ary = Array.new
		i = 0
		Card.all.each do |card|
			c_id = card.boardable_id.to_s
			b_id = board.id.to_s
			if card.leaveDate != nil 
				if c_id == b_id
					ary[i] = card.name
					i += 1
					ary[i] = ((card.leaveDate-card.enterDate)/60/60/24).round(2)
					i += 1
				end
			end
		end
		return ary
	end

	def self.get_user_trello_boards(name)
		if user = Trello::Member.find(name)
			boards = user.boards.to_s
			info = get_boards_info(boards)
			i = 0
			while i < info.length
				if Board.find_by_name(info[i]) == nil
					name = info[i]
					i += 1
					url_id = info[i]
					i += 1
					count = Trello::Board.find(url_id).cards.count
					in_dev = trello_card_count_in_dev(url_id)
					past_dev = trello_card_count_past_dev(url_id)
					bug_cards = find_trello_bug_cards(url_id)
					board = Board.create(:name => name, :url_id => url_id, :card_count => count, :in_dev => in_dev, :past_dev => past_dev, :bug_cards => bug_cards)
					board.save
				else
					i += 2
				end
			end
		else
			return "User does not exist"
		end
	end

	def self.get_boards_info(boards)
		ary = Array.new
		i = 0
		temp = boards.partition("\", :description=>\"")
		while temp.last != ""
			temp2 = temp.first.partition("\", :name=>\"")		
			ary[i] = temp2.last
			i += 1
			ary[i] = temp2.first.partition(":id=>\"").last
			i+=1
			temp = temp.last.partition("\", :description=>\"")
		end
		return ary 
	end

	def self.trello_card_count_in_dev(board)
    board = Trello::Board.find(board)
    list_id = find_trello_list_id(board.lists.to_s, "DEVELOPMENT IN PROGRESS")
    if list_id == ""
      list_id =find_trello_list_id(board.lists.to_s, "Development In Progress")
    end
    if list_id == ""
      return -1
    end
    list = Trello::List.find(list_id)
    return (list.cards.count.to_f / board.cards.count) * 100
  end

  def self.trello_card_count_past_dev(board)
    board = Trello::Board.find(board)
    list_id = find_trello_list_id(board.lists.to_s, "DEVELOPMENT IN PROGRESS")
    if list_id == ""
      list_id =find_trello_list_id(board.lists.to_s, "Development In Progress")
    end
    if list_id == ""
      return -1
    end
    cards = Trello::List.find(list_id).cards.count
    names = find_trello_list_names(board.lists.to_s.partition(list_id).first)
    names.each do |name|
      id = find_trello_list_id(board.lists.to_s, name)
      list = Trello::List.find(id)
      cards += list.cards.count
    end
    return ((board.cards.count - cards).to_f / board.cards.count) * 100
  end

  def self.find_trello_bug_cards(board)
    board = Trello::Board.find(board)
    card_ids = find_trello_card_ids(board.cards.to_s)
    ary = Array.new(board.cards.count)
    i = 0
    card_ids.each do |card|
      label = Trello::Card.find(card)
      ary[i] = label.labels.to_s
      i += 1
    end
    i = 0
    ary.each do |card|
      if card != nil
        if card.partition("Bug").last != ""
          i += 1
        end
      end
    end
    return i
  end

  def self.find_trello_list_id(lists, name)
    if lists.partition(name).last != ""
      list = lists.partition(name).first
      while list.partition(":id=>").last != ""
        list = list.partition(":id=>").last
      end
      return list.partition(", :name").first.gsub("\"", "")
    end
    return ""
  end

  def self.find_trello_list_names(lists)
    ary = Array.new
    i = 0
    while lists.partition("name=>\"").last != ""
      lists = lists.partition("name=>\"").last
      ary[i] = lists.partition("\", ").first
      i += 1
    end
    return ary
  end

  def self.find_trello_card_ids(cards)
    ary = Array.new
    i = 0
    while cards.partition(":id=>\"").last != ""
      cards = cards.partition(":id=>\"").last
      ary[i] = cards.partition("\", ").first
      i += 1
    end
    return ary
  end

  def self.to_csv
  	ary = Array.new
  	ary[0] = "Trello Boards"
  	ary[1] = "% cards in Dev"
  	ary[2] = "% cards past Dev"
  	ary[3] = "# with Bugs"
  	CSV.generate do |csv|
  		csv << ary
  		i = 0
  		self.all.each do |board|
  			board_info = Array.new
  			board_info[0] = board.name.truncate(15, separator: ' ')
  			board_info[1] = board.in_dev
  			board_info[2] = board.past_dev
  			board_info[3] = board.bug_cards
  			csv << board_info
  		end
  	end		
	end

end