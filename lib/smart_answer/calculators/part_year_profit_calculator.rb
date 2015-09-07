module SmartAnswer
  module Calculators
    class PartYearProfitCalculator
      include ActiveModel::Model

      attr_accessor :tax_credits_award_ends_on, :accounts_end_month_and_day, :taxable_profit
      attr_accessor :ceased_trading_on

      def valid_ceased_trading_date?(date)
        tax_year.include?(date)
      end

      def tax_year
        TaxYear.on(tax_credits_award_ends_on)
      end

      def basis_period
        if ceased_trading_on
          DateRange.new(begins_on: accounting_period.begins_on, ends_on: ceased_trading_on)
        else
          accounting_period
        end
      end

      def accounting_period
        YearRange.new(begins_on: accounting_year_start_date)
      end

      def tax_credits_part_year
        DateRange.new(begins_on: tax_year.begins_on, ends_on: [tax_credits_award_ends_on, ceased_trading_on].compact.min)
      end

      def profit_per_day
        (taxable_profit / basis_period.number_of_days).floor(2)
      end

      def part_year_taxable_profit
        if basis_period == tax_credits_part_year
          taxable_profit
        else
          pro_rata_taxable_profit
        end
      end

      def pro_rata_taxable_profit
        (profit_per_day * tax_credits_part_year.number_of_days).floor
      end

      private

      def accounting_period_end_date_in_the_tax_year_that_tax_credits_award_ends
        accounting_date = accounts_end_month_and_day.change(year: tax_year.begins_on.year)
        accounting_date += 1.year unless tax_year.include?(accounting_date)
        accounting_date
      end

      alias accounting_year_end_date accounting_period_end_date_in_the_tax_year_that_tax_credits_award_ends

      def accounting_year_start_date
        accounting_year_end_date - 1.year + 1
      end
    end
  end
end
