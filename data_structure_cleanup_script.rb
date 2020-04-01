
require 'yaml'

cleaned_data = YAML.load_file('south_africa_provincial_stats.yml').map do |day|
  obj = {
    date: day[:date],
    total: day[:total],
    unnallocated: day[:unnallocated],
    deaths: day[:deaths],
    sources: day[:sources],
    tests_done: day[:tests_done],
    negative_tests_results: day[:negative_tests_results],
    gender: {
      male: day.dig(:gender, :male) || day[:male],
      female: day.dig(:gender, :female) || day[:female],
      unknown: day.dig(:gender, :unknown) || day[:unknown]
    },
    local_transmissions: day[:local_transmissions]
  }

  %i(eastern_cape kwazulu_natal mpumalanga western_cape northern_cape north_west free_state gauteng limpopo).each do |place|
    obj[place] = {
      total: day[place].is_a?(Hash) ? day.dig(place, :total) : day[place],
      deaths: day[place].is_a?(Hash) ? day.dig(place, :deaths) : 0 ,
    }
  end
  obj
end

require 'pry'
binding.pry