require 'yaml'
require 'csv'
require 'pry'
require 'date'

srand(115032730400174366788466674494640623225)

#Can't use stats from days where there are no official tests done stats
current_stats = YAML.load_file('south_africa_provincial_stats.yml').reject{|v| v[:tests_done].zero?}

current_stats.each.with_index do |day, index|
  if index == 0
    current_stats[index][:new_cases] = day[:total]
    current_stats[index][:new_tests_done] = day[:tests_done]
  else
    current_stats[index][:new_cases] = day[:total] - current_stats[index - 1][:total]
    current_stats[index][:new_tests_done] = day[:tests_done] - current_stats[index - 1][:tests_done]
  end
end


average_daily_increase_in_testing = current_stats.map{|v| v[:new_tests_done]}.sum / current_stats.size

# Collect ratio of new cases to new tests to get test accuracy (How often do we test the right people)
new_case_detection_chance = current_stats.map{|v| (v[:total].to_f / v[:tests_done])}.sum

current_stats.each.with_index do |day, index|
  _new_case_detection_chance = index.zero? ? 0 : current_stats[0..(index - 1)].map{|v| (v[:total].to_f / v[:tests_done])}.sum
  _average_daily_increase_in_testing = index.zero? ? 0 : current_stats[0..(index - 1)].map{|v| v[:new_tests_done]}.sum / current_stats.size
  current_stats[index][:projected_new_tests_done] = index.zero? ? 0 : (day[:new_tests_done] || day[:projected_new_tests_done]) + _average_daily_increase_in_testing - current_stats[index - 1][:test_error_margin].to_f
  current_stats[index][:projected_new_cases] = (current_stats[index - 1][:new_tests_done] || current_stats[index - 1][:projected_new_tests_done]) * _new_case_detection_chance
  current_stats[index][:test_error_margin] = index.zero? ? 0 : ((current_stats[index][:projected_new_tests_done].to_f - current_stats[index][:new_tests_done].to_f).abs).ceil
  current_stats[index][:case_error_margin] = index.zero? ? 0 : ((current_stats[index][:projected_new_cases].to_f - current_stats[index][:new_cases].to_f).abs).ceil
end

# average_margin_of_error = 

projection_length = 30 #days

projection_length.times do
  current_stats << {
    date: (Date.parse(current_stats.last[:date]) + 1).strftime("%d %b %Y"),
    projected_new_tests_done: (current_stats.last[:new_tests_done] || current_stats.last[:projected_new_tests_done]) + average_daily_increase_in_testing,
    projected_new_cases: (current_stats.last[:new_tests_done] || current_stats.last[:projected_new_tests_done]) * new_case_detection_chance,
  }
end

doc = CSV.generate do |csv|
  csv << ['Total Tests Done', 'Total Positive Cases', 'Date', 'New Cases', 'New Tests Done', 'Projected New Cases', 'Projected New Tests', 'Test Projection Error Margin', 'Case Projection Error Margin']
  current_stats.each do |day|
    csv << [
      [day[:tests_done], day[:total]].max, 
      day[:total], 
      day[:date], 
      day[:new_cases],
      day[:new_tests_done],
      day[:projected_new_cases] ? day[:projected_new_cases].ceil : nil,
      day[:projected_new_tests_done],
      day[:test_error_margin],
      day[:case_error_margin]
    ]
  end
end

File.write('testing_vs_cases_projection.csv', doc)