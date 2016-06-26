#!/usr/bin/env ruby

require 'csv'
require 'json'

CSV_PARAMS = { headers: true, col_sep: ';', encoding: 'UTF-8' }
INFO_FIELDS = %w(info:de info:en info:es info:fr info:it info:nl info:cs info:da info:hu
                 info:ja info:ko info:pl info:pt info:ru info:sv info:tr info:zh)
SYSTEMS = %w(sncf idtgv db busbud ouigo trenitalia ntv hkx renfe atoc)

def reject_nil_values(hash)
  hash.select { |_, v| !v.nil? }
end

def transform(row)
  transformed_row = {
    'id'             => row['id'],
    'is_suggestable' => row['is_suggestable'] == 't' ? true : false,
    'name'           => row['name'],
    'slug'           => row['slug'],
    'uic'            => row['uic']
  }

  if !row['latitude'].nil? && !row['longitude'].nil?
    transformed_row['latitude'] = row['latitude'].to_f
    transformed_row['longitude'] = row['longitude'].to_f
  end

  transformed_row['parent_station_id'] = row['parent_station_id']

  if row['is_city'] == 't'
    transformed_row['is_city'] = true
  end

  if row['is_main_station'] == 't'
    transformed_row['is_main_station'] = true
  end

  transformed_row.merge!(
    'country'   => row['country'],
    'time_zone' => row['time_zone'],
    'same_as'   => row['same_as']
  ).merge!(format_systems(row)).merge!(format_info(row))

  reject_nil_values(transformed_row)
end

def format_info(row)
  info = {}
  INFO_FIELDS.each do |info_field|
    key = info_field[-2, 2]
    if !row[info_field].nil?
      info[key] = row[info_field]
    end
  end

  if !info.empty?
    { 'info' => info.sort.to_h }
  else
    {}
  end
end

def format_systems(row)
  systems = {}

  SYSTEMS.each do |system|
    if !row["#{system}_id"].nil?
      system_hash = { 'id' => row["#{system}_id"] }

      if row["#{system}_is_enabled"] == 't'
        system_hash['is_enabled'] = true
      end

      if row["#{system}_self_service_machine"] == 't'
        system_hash['has_self_service_machine'] = true
      end

      system_hash.merge!(
        'uic8'    => row["uic8_#{system}"],
        'tvs_id'  => row["#{system}_tvs_id"],
        'rtvt_id' => row["#{system}_rtvt_id"],
        'rtiv_id' => row["italo_rtiv_id"]
      )

      system_hash = reject_nil_values(system_hash)

      if !system_hash.empty?
        systems[system] = system_hash
      end
    end
  end

  if !systems.empty?
    { 'systems' => systems.sort.to_h }
  else
    {}
  end
end


stations_csv = CSV.read('stations.csv', CSV_PARAMS)

transformed_rows = stations_csv.map { |row| transform(row) }

File.open("stations.json", "w") do |file|
  file.write(JSON.pretty_generate(transformed_rows))
end
