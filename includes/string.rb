#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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

class String

  def wildcard_match(s)
   
    # Since this is primarily going to be used for hostmask matches, we should
    # escape these so that character classes aren't used, as that might
    # produce unexpected results.
    s.gsub!(/([\[\]])/, '\\\\\1')

    # Wildcard matches can be done with fnmatch, a globbing function. This
    # doesn't touch the filesystem.
    File.fnmatch(s, self)

  end

end
