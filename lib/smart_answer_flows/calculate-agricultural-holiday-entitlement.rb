module SmartAnswer
  class CalculateAgriculturalHolidayEntitlementFlow < Flow
    def define
      name 'calculate-agricultural-holiday-entitlement'
      status :published
      satisfies_need "100143"

      calculator = Calculators::AgriculturalHolidayEntitlementCalculator.new()

      multiple_choice :work_the_same_number_of_days_each_week? do
        option "same-number-of-days" => :how_many_days_per_week?
        option "different-number-of-days" => :what_date_does_holiday_start?
      end

      multiple_choice :how_many_days_per_week? do
        option "7-days"
        option "6-days"
        option "5-days"
        option "4-days"
        option "3-days"
        option "2-days"
        option "1-day"

        calculate :days_worked_per_week do |response|
          # XXX: this is a bit nasty and takes advantage of the fact that
          # to_i only looks for the very first integer
          response.to_i
        end

        next_node :worked_for_same_employer?
      end

      date_question :what_date_does_holiday_start? do
        from { Date.civil(Date.today.year, 1, 1) }
        to { Date.civil(Date.today.year + 1, 12, 31) }

        calculate :weeks_from_october_1 do |response|
          calculator.weeks_worked(response)
        end

        next_node :how_many_total_days?
      end

      multiple_choice :worked_for_same_employer? do
        option "same-employer" => :done
        option "multiple-employers" => :how_many_weeks_at_current_employer?

        save_input_as :worked_for_same_employer_for_a_year
      end

      value_question :how_many_total_days?, parse: Integer do

        precalculate :available_days do
          calculator.available_days
        end

        validate { |response| response <= available_days }

        calculate :total_days_worked do |response|
          response
        end

        next_node :worked_for_same_employer?
      end

      value_question :how_many_weeks_at_current_employer?, parse: Integer do
        next_node :done

        #Has to be less than a full year
        validate { |response| response < 52 }

        save_input_as :weeks_at_current_employer
      end

      outcome :done do
        precalculate :holiday_entitlement_days do
          # This is calculated as a flat number based on the days you work
          # per week
          days_worked = if days_worked_per_week
            days_worked_per_week
          else
            total_days_worked.to_f / weeks_from_october_1.to_f
          end

          if worked_for_same_employer_for_a_year == 'multiple-employers'
            calculator.pro_rata_holiday_entitlement(days_worked, weeks_at_current_employer)
          else
            calculator.holiday_days(days_worked)
          end
        end
      end
    end
  end
end
