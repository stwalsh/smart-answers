require 'date'

module SmartAnswer::Calculators
  class AgriculturalHolidayEntitlementCalculator
    # created for the agricultural holiday entitlement calculator

    attr_accessor :days_worked_per_week
    attr_accessor :holiday_starts_on
    attr_accessor :worked_for_same_employer_for_a_year
    attr_accessor :weeks_at_current_employer
    attr_accessor :total_days_worked

    def calculation_period
      # Agricultural holiday calculations run from Oct 1 - Oct 1
      this_year_period = Date.civil(Date.today.year, 10, 1)
      if Date.today > this_year_period
        this_year_period
      else
        # last year's Oct 1
        Date.civil(Date.today.year.to_i - 1, 10, 1)
      end
    end

    def weeks_worked(holiday_start)
      days = (holiday_start.to_datetime - calculation_period.to_datetime).to_i
      days / 7
    end

    def available_days
      (Date.today.to_datetime - calculation_period.to_datetime).to_i
    end

    def full_holiday_entitlement(days_worked_per_week)
      days_worked_per_week = days_worked_per_week.to_f
      if days_worked_per_week > 6
        38
      elsif days_worked_per_week > 5
        35
      elsif days_worked_per_week > 4
        31
      elsif days_worked_per_week > 3
        25
      elsif days_worked_per_week > 2
        20
      elsif days_worked_per_week > 1
        13
      else
        7.5
      end
    end

    def pro_rata_holiday_entitlement(days_worked_per_week, weeks_at_current_employer)
      sprintf("%.1f", (full_holiday_entitlement(days_worked_per_week) * (weeks_at_current_employer / 52.0)))
    end

    def holiday_entitlement_days
      # This is calculated as a flat number based on the days you work
      # per week
      days_worked = if days_worked_per_week
        days_worked_per_week
      else
        average_number_of_days_worked_per_week
      end

      if worked_for_same_employer_for_a_year
        full_holiday_entitlement(days_worked)
      else
        pro_rata_holiday_entitlement(days_worked, weeks_at_current_employer)
      end
    end

    def average_number_of_days_worked_per_week
      total_days_worked.to_f / weeks_worked(holiday_starts_on).to_f
    end
  end
end
