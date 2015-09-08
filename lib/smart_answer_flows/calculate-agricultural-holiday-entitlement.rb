module SmartAnswer
  class CalculateAgriculturalHolidayEntitlementFlow < Flow
    def define
      name 'calculate-agricultural-holiday-entitlement'
      status :published
      satisfies_need "100143"

      multiple_choice :work_the_same_number_of_days_each_week? do
        option "same-number-of-days" => :how_many_days_per_week?
        option "different-number-of-days" => :what_date_does_holiday_start?

        calculate :calculator do
          Calculators::AgriculturalHolidayEntitlementCalculator.new
        end
      end

      multiple_choice :how_many_days_per_week? do
        option "7-days"
        option "6-days"
        option "5-days"
        option "4-days"
        option "3-days"
        option "2-days"
        option "1-day"

        next_node do |response|
          # XXX: this is a bit nasty and takes advantage of the fact that
          # to_i only looks for the very first integer
          calculator.days_worked_per_week = response.to_i
          :worked_for_same_employer?
        end
      end

      date_question :what_date_does_holiday_start? do
        from { Date.civil(Date.today.year, 1, 1) }
        to { Date.civil(Date.today.year + 1, 12, 31) }

        next_node do |response|
          calculator.holiday_starts_on = response
          :how_many_total_days?
        end
      end

      multiple_choice :worked_for_same_employer? do
        option "same-employer"
        option "multiple-employers"

        next_node do |response|
          if response == "same-employer"
            calculator.worked_for_same_employer_for_a_year = true
            :done
          else
            calculator.worked_for_same_employer_for_a_year = false
            :how_many_weeks_at_current_employer?
          end
        end
      end

      value_question :how_many_total_days?, parse: Integer do
        precalculate :available_days do
          calculator.available_days
        end

        validate { |response| response <= available_days }

        next_node do |response|
          calculator.total_days_worked = response
          :worked_for_same_employer?
        end
      end

      value_question :how_many_weeks_at_current_employer?, parse: Integer do
        next_node do |response|
          calculator.weeks_at_current_employer = response
          :done
        end

        #Has to be less than a full year
        validate { |response| response < 52 }
      end

      outcome :done
    end
  end
end
