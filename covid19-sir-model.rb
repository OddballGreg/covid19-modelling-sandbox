require 'pry'
require 'date'

#Standard SIR model assumes non-changing population
def SIR_model(conditions, infection_rate, removal_rate, total_population)
  suseptible = conditions[:suseptible]
  infectious = conditions[:infectious]
  removed = conditions[:removed]

  dS_dt = -(infection_rate*suseptible*infectious) / total_population #change in susceptible
  dI_dt = ((infection_rate*suseptible*infectious) / total_population) - removal_rate*infectious #change in infectious
  dR_dt = removal_rate*infectious #change in removed

  [dS_dt.floor, dI_dt.floor, dR_dt.floor]
end

first_case_date = Date.parse('5 March 2020') #First confirmed case date http://www.nicd.ac.za/first-case-of-covid-19-coronavirus-reported-in-sa/
current_date = Date.parse('29 March 2020')
pandemic_duration = (current_date - first_case_date).to_i

#initial conditions
south_african_population = 58_780_000 #2019 estimate http://www.statssa.gov.za/publications/P0302/P03022019.pdf
recoveries = 32 #reported as of 29 March 2020 sacoronavirus.co.za
deaths = 2 #reported as of 29 March 2020 sacoronavirus.co.za
positive_cases_identified = 1280 #reported as of 29 March 2020 sacoronavirus.co.za

known_active_infectious = positive_cases_identified - deaths - recoveries

#Not knowning how long on average it takes us identify cases means we can't tell how long they're out potentially spreading it
#lead_time_to_identificiation = ?

#Knowing how well we are tracing the contacts of a detected case compared to their standard infection ratio would help us to know how much we are reducing spread
#contact_tracing_efficacy = ?

#cases in icu https://www.iol.co.za/capeargus/news/ten-hospitalised-four-in-icu-as-covid-19-cases-in-western-cape-rise-45706456
in_icu = 4 #one day old information


# https://www.worldometers.info/coronavirus/coronavirus-incubation-period/
coronavirus_incubation_period_highest = 14
coronavirus_incubation_period_lowest = 1

infection_rate = 1.13 #known as alpha. https://mg.co.za/article/2020-03-12-concern-that-hospitals-wont-be-able-to-cope-with-covid-19/
removed_0 = recoveries + deaths #R0 Initial quantity removed
death_rate = deaths.to_f / removed_0 #Portion of removed by death
recovery_rate = recoveries.to_f / removed_0 #Portion of removed by recovery
#south african removal rate based on current values
#removal_rate = (removed_0.to_f / positive_cases_identified) / pandemic_duration #gamma, ratio of removed to identified averaged over course of pandemic
#global average removal rate
removal_rate = 0.17

#Worst case estimate that each positively identified case was able to spread the infection the average value before being identified and isolated
worst_case_estimated_infectious_cases = (positive_cases_identified * infection_rate) 
coronavirus_incubation_period_highest.times do #simulate giving each case the maximum number of days to infect others
  worst_case_estimated_infectious_cases = worst_case_estimated_infectious_cases * infection_rate
end

infectious_0 = worst_case_estimated_infectious_cases #I0 estimated worst case of coronavirus cases
# infectious_0 = positive_cases_identified #I0 best case of infectious coronavirus cases
suseptible_0 = south_african_population - infectious_0 - removed_0 #S0 South African Population - initial infected and removed

#timeline
days = 90
# steps = 17 #Average recovery time for a patient is 17 days https://www.businessinsider.co.za/coronavirus-covid19-day-by-day-symptoms-patients-2020-2?r=US&IR=T

iterations = days

conditions = {suseptible: suseptible_0.floor, infectious: infectious_0.floor, removed: removed_0, deaths: deaths, recoveries: recoveries}

changes_at_timestep = {}
conditions_at_timestep = {-1 => conditions}

iterations.times do |iteration|
  last_iteration = iteration-1
  changes_at_timestep[iteration] = SIR_model(conditions_at_timestep[last_iteration], infection_rate, removal_rate, south_african_population)
  conditions_at_timestep[iteration] = {}
  conditions_at_timestep[iteration][:suseptible] = (conditions_at_timestep[last_iteration][:suseptible] + changes_at_timestep[iteration][0])
  conditions_at_timestep[iteration][:infectious] = (conditions_at_timestep[last_iteration][:infectious] + changes_at_timestep[iteration][1])
  conditions_at_timestep[iteration][:removed   ] = (conditions_at_timestep[last_iteration][:removed   ] + changes_at_timestep[iteration][2])

  conditions_at_timestep[iteration][:deaths] = (conditions_at_timestep[iteration][:removed   ] * death_rate).floor
  conditions_at_timestep[iteration][:recoveries] = (conditions_at_timestep[iteration][:removed   ] * recovery_rate).ceil
end

require 'csv'

doc = CSV.generate do |csv|
  csv << %w(date suseptible infectious removed deaths recoveries)
  conditions_at_timestep.each do |k ,v|
    csv << [current_date+k, v[:suseptible], v[:infectious], v[:removed], v[:deaths], v[:recoveries]]
  end
end

File.write('covid19-sir-predictions.csv', doc)

#notes
# Death predictions seem extremely grim and improbable. Likely as more data is gathered will be able to more appropriately scale this
# Introduction of hospitatlization & ICU metrics may be valuable for their relation to recovery and death metrics as well as modelling reduction in infectiousness
# Estimated 2 weeks until signs of Lockdown efficacy become evident in data.
# An interesting excersies would be to run the model from every day of the pandemic start since march 5th as an entry point, and compare to real stats to determine margin of error