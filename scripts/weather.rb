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

# TODO: refactor more

need_module! 'http'

require 'rexml/document'

register 'Weather information look-ups via Weather Underground (wunderground.com).'

command 'weather', 'View current conditions for the specified location.' do
  argc! 1

  uri = URI('http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml')
  opts = {:query => @params.join(' ')}

  http_get(uri, opts) do |http|
    root = (REXML::Document.new(http.response)).root

    weather = root.elements['//weather'].text rescue nil

    if weather.nil?
      raise 'That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.'
    end

    credit          = root.elements['//credit'].text
    updatedTime     = root.elements['//observation_epoch'].text.to_i
    localTime       = root.elements['//local_time'].text
    stationLocation = root.elements['//observation_location/full'].text
    temperature     = root.elements['//temperature_string'].text
    humidity        = root.elements['//relative_humidity'].text
    wind            = root.elements['//wind_string'].text
    pressure        = root.elements['//pressure_string'].text
    dewpoint        = root.elements['//dewpoint_string'].text
    link            = root.elements['//forecast_url'].text
    
    updated = "#{Time.at(updatedTime).to_fuzzy_duration_s} ago"

    data = {
      "[#{credit} for #{stationLocation}]" => {
        'Currently' => weather,
        'Temp'      => temperature,
        'Humidity'  => humidity,
        'Wind'      => wind,
        #'Dewpoint' => dewpoint,
        'Updated'   => updated,
        'URL'       => link
      }
    }

    reply data

  end
end

command 'temp', 'View current temperature for the specified location.' do
  argc! 1

  uri = URI('http://api.wunderground.com/auto/wui/geo/WXCurrentObXML/index.xml')
  opts = {:query => @params.join(' ')}

  http_get(uri, opts) do |http|
    root = (REXML::Document.new(http.response)).root

    weather = root.elements['//weather'].text rescue nil

    if weather.nil?
      raise 'That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.'
    end

    credit          = root.elements['//credit'].text
    stationLocation = root.elements['//observation_location/full'].text
    temperature     = root.elements['//temperature_string'].text

    data = {
      "[#{credit} for #{stationLocation}]" => {
        'Temperature' => temperature
      }
    }

    reply data
  end
end

command 'forecast', 'View a short-term forecast for the specified location.' do
  argc! 1

  uri = URI('http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml')
  opts = {:query => @params.join(' ')}

  http_get(uri, opts) do |http|
    root = (REXML::Document.new(http.response)).root.elements['//txt_forecast']

    date = root.elements['date'].text rescue nil

    if date.nil?
      raise 'That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.'
    end

    output = []

    output << "[\02Forecast for #{@params.join ' '}\02 as of \02#{date}\02]"

    count = 0

    root.elements.each('forecastday') do |element|
      title = element.elements['title'].text

      text = html_decode element.elements['fcttext'].text

      output << "[\02#{title}\02] #{text}"

      count += 1
      break if count == 2
    end

    if count.zero?
      raise 'That does not appear to be a valid location. If it is, try being more specific, or specify the location in another way.'
    end

    reply output.join(' ')
  end
end

# vim: set tabstop=2 expandtab:
