require_relative "../../test_helper"

module SmartAnswer
  module Calculators
    class PartYearProfitCalculatorTest < ActiveSupport::TestCase
      context 'validation of ceased trading date' do
        setup do
          @calculator = PartYearProfitCalculator.new
          @calculator.tax_credits_award_ends_on = Date.parse('2015-08-01')
        end

        should 'be valid if the ceased trading date is in the tax year that the tax credits award ended' do
          assert @calculator.valid_ceased_trading_date?(Date.parse('2015-04-06'))
          assert @calculator.valid_ceased_trading_date?(Date.parse('2016-04-05'))
        end

        should 'be invalid if the ceased trading date is before the tax year that the tax credits award ended' do
          refute @calculator.valid_ceased_trading_date?(Date.parse('2015-04-05'))
        end

        should 'be invalid if the ceased trading date is after the tax year that the tax credits award ended' do
          refute @calculator.valid_ceased_trading_date?(Date.parse('2016-04-06'))
        end
      end

      context 'tax year' do
        setup do
          @tax_credits_award_ends_on = Date.parse('2016-02-20')
          @calculator = PartYearProfitCalculator.new(tax_credits_award_ends_on: @tax_credits_award_ends_on)
        end

        should 'calculate tax year in which tax credits award ends' do
          tax_year = stub('tax-year')
          TaxYear.stubs(:on).with(@tax_credits_award_ends_on).returns(tax_year)
          assert_equal tax_year, @calculator.tax_year
        end
      end

      context 'accounts end on' do
        setup do
          @calculator = PartYearProfitCalculator.new(accounts_end_month_and_day: Date.parse('0000-06-30'))
        end

        context 'when tax credits award ends in 2015-16 tax year' do
          setup do
            @calculator.tax_credits_award_ends_on = Date.parse('2016-04-05')
          end

          should 'be date within 2015-16 tax year with specified month and day' do
            assert_equal Date.parse('2015-06-30'), @calculator.accounting_period.ends_on
          end
        end

        context 'when tax credits award ends in 2016-17 tax year' do
          setup do
            @calculator.tax_credits_award_ends_on = Date.parse('2016-04-06')
          end

          should 'be date within 2016-17 tax year with specified month and day' do
            assert_equal Date.parse('2016-06-30'), @calculator.accounting_period.ends_on
          end
        end
      end

      context 'basis period' do
        setup do
          @accounting_period = YearRange.new(begins_on: Date.parse('2015-01-01'))
          @calculator = PartYearProfitCalculator.new
          @calculator.stubs(accounting_period: @accounting_period)
        end

        should 'return the accounting period when the business is still trading' do
          @calculator.ceased_trading_on = nil
          assert_equal @accounting_period, @calculator.basis_period
        end

        should 'return the period between the start of the accounting period and the ceased trading date' do
          @calculator.ceased_trading_on = Date.parse('2015-02-01')
          expected_range = DateRange.new(begins_on: Date.parse('2015-01-01'), ends_on: Date.parse('2015-02-01'))
          assert_equal expected_range, @calculator.basis_period
        end
      end

      context 'accounting period' do
        setup do
          @accounts_end_on = Date.parse('2015-12-31')
          @calculator = PartYearProfitCalculator.new
          @calculator.stubs(:accounting_year_end_date).returns(@accounts_end_on)
        end

        should 'begin a year before the accounts end' do
          assert_equal Date.parse('2015-01-01'), @calculator.accounting_period.begins_on
        end

        should 'end on the date the accounts end' do
          assert_equal @accounts_end_on, @calculator.accounting_period.ends_on
        end
      end

      context 'tax credits part year' do
        setup do
          @tax_credits_award_ends_on = Date.parse('2016-02-20')
          @calculator = PartYearProfitCalculator.new(tax_credits_award_ends_on: @tax_credits_award_ends_on)
        end

        should 'begin at the beginning of the tax year in which the tax credits award ends' do
          assert_equal Date.parse('2015-04-06'), @calculator.tax_credits_part_year.begins_on
        end

        should 'end on the date the tax credits award ends' do
          assert_equal @tax_credits_award_ends_on, @calculator.tax_credits_part_year.ends_on
        end

        should 'end on the date the business ceases trading if that date is before the date the tax credits award ends' do
          ceased_trading_on = Date.parse('2016-02-19')
          @calculator.ceased_trading_on = ceased_trading_on
          assert_equal ceased_trading_on, @calculator.tax_credits_part_year.ends_on
        end
      end

      context 'profit per day' do
        setup do
          @number_of_days_in_basis_period = 366
          @taxable_profit = Money.new(15000)
          basis_period = stub('basis_period', number_of_days: @number_of_days_in_basis_period)
          @calculator = PartYearProfitCalculator.new(taxable_profit: @taxable_profit)
          @calculator.stubs(:basis_period).returns(basis_period)
        end

        should 'divide profit by number of days in basis period and round down to nearest penny' do
          expected_profit_per_day = @taxable_profit / @number_of_days_in_basis_period
          assert_not_equal expected_profit_per_day, @calculator.profit_per_day, 'Not rounded down to nearest penny'
          assert_equal expected_profit_per_day.floor(2), @calculator.profit_per_day
        end
      end

      context 'pro rata taxable profit' do
        setup do
          @number_of_days_in_tax_credits_part_year = 321
          @profit_per_day = 40.98
          tax_credits_part_year = stub('tax_credits_part_year', number_of_days: @number_of_days_in_tax_credits_part_year)
          @calculator = PartYearProfitCalculator.new
          @calculator.stubs(tax_credits_part_year: tax_credits_part_year, profit_per_day: @profit_per_day)
        end

        should 'multiply profit per day by number of days in tax credits part year and round down to nearest pound' do
          expected_part_year_taxable_profit = @profit_per_day * @number_of_days_in_tax_credits_part_year
          assert_not_equal expected_part_year_taxable_profit, @calculator.pro_rata_taxable_profit, 'Not rounded down to nearest pound'
          assert_equal expected_part_year_taxable_profit.floor, @calculator.pro_rata_taxable_profit
        end
      end

      context 'part year taxable profit' do
        setup do
          @tax_year_begins_on = Date.parse('2015-04-06')
          @tax_credit_award_ends_on = Date.parse('2015-08-01')
          @tax_credits_part_year = DateRange.new(begins_on: @tax_year_begins_on, ends_on: @tax_credit_award_ends_on)
          @calculator = PartYearProfitCalculator.new
          @calculator.stubs(tax_credits_part_year: @tax_credits_part_year)
        end

        should 'return taxable profit figure when the award period matches the basis period' do
          basis_period = DateRange.new(begins_on: @tax_year_begins_on, ends_on: @tax_credit_award_ends_on)
          @calculator.stubs(basis_period: basis_period)
          @calculator.stubs(taxable_profit: 10_000)

          assert_equal 10_000, @calculator.part_year_taxable_profit
        end

        should 'return pro rata taxable profit when the award period and basis period are different' do
          basis_period = YearRange.new(begins_on: @tax_year_begins_on)
          @calculator.stubs(basis_period: basis_period)
          @calculator.stubs(pro_rata_taxable_profit: 10_000)

          assert_equal 10_000, @calculator.part_year_taxable_profit
        end
      end
    end
  end
end
