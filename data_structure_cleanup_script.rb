
require 'yaml'

cleaned_data = YAML.load_file('south_africa_provincial_stats.yml').map do |day|
  obj = {
    date: day[:date],
    total: day[:total].to_i,
    unnallocated: day[:unnallocated].to_i,
    deaths: day[:deaths].to_i,
    sources: day[:sources],
    tests_done: day[:tests_done].to_i,
    negative_tests_results: day[:negative_tests_results].to_i,
    gender: {
      male: day.dig(:gender, :male).to_i || day[:male].to_i,
      female: day.dig(:gender, :female).to_i || day[:female].to_i,
      unknown: day.dig(:gender, :unknown).to_i || day[:unknown].to_i
    },
    local_transmissions: day[:local_transmissions].to_i
  }

  %i(eastern_cape kwazulu_natal mpumalanga western_cape northern_cape north_west free_state gauteng limpopo).each do |place|
    obj[place] = {
      total: day[place].is_a?(Hash) ? day.dig(place, :total).to_i : day[place].to_i,
      deaths: day[place].is_a?(Hash) ? day.dig(place, :deaths).to_i : 0 ,
    }
  end
  obj
end

require 'pry'
binding.pry