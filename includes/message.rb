
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

class Message
  attr_reader :origin, :destination, :type, :text, :raw, :raw_arr,
    :nick, :user, :host, :connection

  # Parse the str as an IRC message and fire appropriate events.
  def initialize(connection, str, outgoing = false)

    arr = str.split

    @stripped = ""
    @raw, @raw_arr = str, arr
    @connection = connection

    # TODO: This whole thing can be done with just one regex!

    if outgoing

      @nick = connection.nick
      @user = connection.user
      @host = connection.client_host
      
      @origin = "#{@nick}!#{@user}@#{@host}"

      @type = arr[0]
      @destination = arr[1]
      
      @text = (str =~ /\A.+\s:(.+)\Z/ ? $1 : "")

    else

      if str[0] == ":"
        # This will be almost all messages.

        @origin = arr[0][1..arr[0].length-1]
        @type = arr[1]
        @destination = arr[2].gsub(/\A:?/, "") # Not always the destination. Oh well.

        if @origin =~ /\A([^ ]+)!([^ ]+)@([^ ]+)/
          @nick, @user, @host = $1, $2, $3
        else
          @nick, @user, @host = "", "", ""
        end

        # Grab the text portion, as in
        # :origin PRIVMSG #dest :THIS TEXT
        @text = (str =~ /\A:.+\s:(.+)\Z/ ? $1 : "")

      else
        # Server PINGs. Not much else.

        @type = arr[0]
        @origin = ""
        @destination = ""

        @text = (str =~ /.+:(.+)\Z/ ? $1 : "")
      end

    end

  end

  # Reply to a message. If an array is given, send each reply separately.
  def reply(str, prefix = true)
    return if silent?

    if str.kind_of? Array
      str.each do |this_str|
        send_reply(this_str, prefix)
      end
    else
      send_reply(str, prefix)
    end
  end

  # Actually send the reply. If prefix is true, prefix each message with the
  # triggering user's nick. If replying in private, never use a prefix, and
  # reply with NOTICE instead.
  def send_reply(str, prefix)
    if str.empty?
      str = "I tried to send you an empty message. Oops!"
    end

    # TODO: Hold additional content for later sending or something.
    #       Just don't try to send it all in multiple messages without
    #       the user asking for it!
    unless self.private?
      str = "PRIVMSG #{@destination} :#{prefix ? @nick + ": " : ""}#{truncate(str, @destination)}"
    else
      str = "NOTICE #{@nick} :#{truncate(str, @nick, true)}"
    end

    @connection.raw(str)
  end

  # Return true if this channel is listed in the silent setting.
  def silent?
    return false if self.private?
    silenced = $bot.config['core']['silent']

    return false if silenced == nil

    silenced = silenced.split(" ")
    
    return false if silenced.empty?

    silenced.each do |s|
      s = s.split(":")

      next if s.length != 2

      return true if s[0] == @connection.name and s[1] == @destination
    end

    return false
  end

  # Attempt to truncate messages in such a way that the maximum
  # amount of space possible is used. This assumes the server will
  # send a full 512 bytes to a client with exactly 1459 format.
  def truncate(message, destination, notice = false)
    prefix_length = @connection.nick.length +
                    @connection.user.length +
                    @connection.client_host.length +
                    destination.length +
                    15

    # PRIVMSG is 1 char longer than NOTICE
    prefix_length += 1 unless notice

    if (prefix_length + message.length) - 512 > 0
      return message[0..511-prefix_length]
    end

    message
  end

  def send_privmsg(target, str)
    raw("PRIVMSG #{target} :#{str}")
  end

  def send_notice(target, str)
    raw("NOTICE #{target} :#{str}")
  end

  # Return true if this message's origin appears to be the bot.
  def me?
    return @connection.nick == @nick
  end

  # Return true if this message doesn't appear to have been sent in a
  # channel.
  def private?
    # TODO: Use CHANTYPES from 003.
    not @destination.start_with? "#" and not @destination.start_with? "&"
  end

  # This has to be separate from our method_missing cheat below because
  # raw is apparently an existing function. Oops! Better than overriding
  # send, though.
  def raw(*args)
    @connection.raw(*args)
  end

  # Should not be called externally.
  def strip(str)
    str.gsub(/(\x0F|\x1D|\02|\03([0-9]{1,2}(,[0-9]{1,2})?)?)/, "")
  end

  # Return the message with formatting stripped.
  def stripped
    return @stripped unless @stripped.empty?

    @stripped = strip(@text)
  end

  # Cheat mode for sending things to the owning connection. Useful for
  # scripts.
  def method_missing(name, *args, &block)
    if @connection.respond_to? name
      @connection.send(name, *args, &block)
    else
      $log.error("Message.method_missing") { "Attempted to call nonexistent method #{name}" }
      throw NoMethodError.new("Attempted to call a nonexistent method #{name}", name, args)
    end
  end
end
