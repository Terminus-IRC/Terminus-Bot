class Cards

  attr_accessor :deck, :discarded, :hands
  
  def initialize
    # sym is the string representing this object in a chat reply
    # suit is one of d, c, h, or s
    # rank is one of A, 2, 3, 4, 5, 6, 7, 8, 9, T, J, K, Q
    @card = Struct.new(:sym, :suit, :rank)

    suit_to_sym = { "d" => "\002\00304\u2666 %s\003\002",
                    "c" => "\002\003\u2663 %s\003\002",
                    "h" => "\002\00304\u2665 %s\003\002",
                    "s" => "\002\003\u2660 %s\003\002" }

    # standard deck of cards
    @fresh_deck = ["d", "c", "h", "s"].map do |suit|
      ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "K", "Q"].map do |rank|
        @card.new(suit_to_sym[suit] % rank, suit, rank)
      end
    end.flatten

    @deck = @fresh_deck.shuffle
    @discarded = Array.new

    @hands = Hash.new
  end

  def draw
    if @deck.empty?
      @deck = @discarded.shuffle
      @discarded = Array.new
    end

    @deck.pop
  end

  def discard(card)
    @discarded << card
  end

  def hand_new(hand)
    hand_discard_all(hand) if @hands.has_key? hand
    @hands[hand] = Array.new
  end

  def has_hand?(hand)
    @hands.has_key? hand
  end

  def has_cards?(hand)
    has_hand? hand and not @hands[hand].empty?
  end

  def hand_draw_one(hand)
    @hands[hand] << draw
  end

  def hand_draw(hand, count)
    (0...count).each { |i| hand_draw_one hand }
  end

  def hand_discard_all(hand)
    @hands[hand].each { |card| discard card }
    @hands[hand] = Array.new
  end

  def hand_each(hand)
    @hands[hand].each { |card| yield card }
  end

end


class Blackjack < Cards

  def hand_score(hand)
    score = 0

    hand_each(hand) do |card|
      if ["J", "Q", "K"].include? card.rank
        score += 10
      elsif card.rank == "A"
        score += (score + 11 > 21) ? 1 : 11
      else
        score += card.rank.to_i
      end
    end

    score
  end

  def hand_to_s(hand)
    "(sum #{hand_score hand}) " << @hands[hand].map { |card| card.sym }.join("  ")
  end

end

def initialize
  register_script("Play blackjack!")

  register_command("blackjack", :cmd_blackjack, 0, 0, "Start a game of blackjack")
  register_event("PRIVMSG", :on_privmsg)

  @cards = Hash.new
end

def card_key(msg)
  return [msg.connection.name, msg.destination]
end

def cmd_blackjack(msg, params)
  @cards[card_key msg] ||= Blackjack.new
  bj = @cards[card_key msg]
  bj.hand_new(msg.nickcanon)
  bj.hand_draw(msg.nickcanon, 2)

  msg.reply("#{bj.hand_to_s(msg.nickcanon)}, use 'hit' and 'stay'")
end

def check_win(msg, bj)
  # run the dealer game
  dealer = "dealer #{msg.nickcanon}"
  bj.hand_new(dealer)
  bj.hand_draw(dealer, 2)
  while bj.hand_score(dealer) < 17
    bj.hand_draw_one(dealer)
  end
  dhand = bj.hand_to_s(dealer)

  # discard piles and get scores
  pscore = bj.hand_score(msg.nickcanon)
  dscore = bj.hand_score(dealer)
  bj.hand_discard_all(msg.nickcanon)
  bj.hand_discard_all(dealer)

  # check win/loss conditions
  if pscore > 21
    msg.reply("#{msg.nick} busts!", false)
  elsif dscore > 21
    msg.reply("Dealer busts with #{dhand}! #{msg.nick} wins!", false)
  elsif dscore == pscore
    msg.reply("Dealer has #{dhand}. It's a tie with #{msg.nick}!", false)
  elsif dscore > pscore
    msg.reply("Dealer has #{dhand}. Dealer beats #{msg.nick}", false)
  elsif dscore < pscore
    msg.reply("Dealer has #{dhand}. #{msg.nick} beats dealer!", false)
  end
end

def on_privmsg(msg)
  bj = @cards[card_key msg]

  return unless bj
  return unless bj.has_cards? msg.nickcanon

  dc = msg.text.downcase

  if dc.start_with? "hit"
    bj.hand_draw_one msg.nickcanon
    msg.reply(bj.hand_to_s(msg.nickcanon))

    check_win(msg, bj) if bj.hand_score(msg.nickcanon) > 21
  elsif dc.start_with? "stay"
    check_win(msg, bj)
  end

end
