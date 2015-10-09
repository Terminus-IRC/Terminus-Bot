#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

register 'Manipulate command aliases.'

event :em_started do
  load_aliases
end

command 'restorealiases', 'Restore all aliases ever added' do
  level! 10
  load_aliases
end

command 'listaliases', 'List all of the aliases' do
  level! 3
  get_all_data.each do |(aliascommand, aliastarget)|
    reply "#{aliascommand} - #{aliastarget}"
  end
end

command 'alias', 'Manipulate the command alias list. Syntax: ADD alias target|DELETE alias' do
  level! 5 and argc! 2

  case @params.first.downcase
  when 'add'
    argc! 3

    aliascommand = @params[1].downcase
    aliastarget = @params[2].downcase
    
    Bot::Commands.create_alias aliascommand, aliastarget
    store_data aliascommand, aliastarget
    
    reply 'Alias created'

  when 'delete', 'del'
    
    aliaskey = @params[1].downcase
    Bot::Commands.delete_alias aliaskey
    delete_data aliaskey 
    
    reply 'Alias deleted.'

  end
end

helpers do

  def load_aliases
    get_all_data.each do |(aliascommand, aliastarget)|
      begin  
        Bot::Commands.create_alias aliascommand.dup, aliastarget.dup
      rescue Exception => e  
        reply e.message
      end  
    end
  end
  
end
# vim: set tabstop=2 expandtab:
