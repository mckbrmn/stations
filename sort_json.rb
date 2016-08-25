#!/usr/bin/env ruby

require 'json'

STATION_KEY_ORDER = %w(id is_suggestable name slug uic latitude longitude parent_station_id
                       is_city is_main_station country time_zone same_as systems info)
SYSTEM_KEY_ORDER  = %w(id is_enabled has_self_service_machine uic8 tvs_id rtvt_id)

def sort(station)
  station = station.sort_by do |key, _|
    STATION_KEY_ORDER.index(key)
  end.to_h

  if station.has_key?('systems')
    station['systems'] = station['systems'].map do |key, value|
      [ key, value.sort_by { |field, _| SYSTEM_KEY_ORDER.index(field) }.to_h ]
    end.sort_by { |key, _| key }.to_h
  end

  if station.has_key?('info')
    station['info'] = station['info'].sort.to_h
  end

  station
end

stations = JSON.parse(File.read("stations.json"))

sorted_stations = stations.map do |station|
  sort(station)
end.sort_by do |station|
  begin
    Float(station['id'])
  rescue
    station['id']
  end
end

puts JSON.pretty_generate(sorted_stations)
