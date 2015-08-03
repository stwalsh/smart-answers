require_relative '../test_helper'

module SmartAnswer
  class DateRangeTest < ActiveSupport::TestCase
    context 'when range is built with begins_on & ends_on' do
      setup do
        @date_range = DateRange.new(begins_on: Date.parse('2000-01-01'), ends_on: Date.parse('2000-01-07'))
      end

      should 'begin on begins_on date' do
        assert_equal Date.parse('2000-01-01'), @date_range.begins_on
      end

      should 'end on ends_on date' do
        assert_equal Date.parse('2000-01-07'), @date_range.ends_on
      end

      should 'include begins_on date' do
        assert @date_range.include?(Date.parse('2000-01-01'))
      end

      should 'include ends_on date' do
        assert @date_range.include?(Date.parse('2000-01-07'))
      end

      should 'include date between begins_on and ends_on' do
        assert @date_range.include?(Date.parse('2000-01-03'))
      end

      should 'include time between begins_on and ends_on' do
        assert @date_range.include?(Time.parse('2000-01-03 03:03:03'))
      end

      should 'not include date before begins_on' do
        refute @date_range.include?(Date.parse('1999-12-31'))
      end

      should 'not include date after ends_on' do
        refute @date_range.include?(Date.parse('2000-01-08'))
      end

      should 'calculate number of days in range' do
        assert_equal 7, @date_range.number_of_days
      end

      should 'equal another DateRange with the same begins_on & ends_on' do
        assert @date_range == @date_range.dup
      end

      should 'not equal another DateRange with a different begins_on' do
        refute @date_range == DateRange.new(begins_on: @date_range.begins_on + 1, ends_on: @date_range.ends_on)
      end

      should 'not equal another DateRange with a different ends_on' do
        refute @date_range == DateRange.new(begins_on: @date_range.begins_on, ends_on: @date_range.ends_on + 1)
      end

      should 'not equal an object which is not a DateRange' do
        sub_class_instance = Class.new(DateRange).new(begins_on: @date_range.begins_on, ends_on: @date_range.ends_on)
        refute @date_range == sub_class_instance
      end

      should 'be equivalent to another DateRange with the same begins_on & ends_on' do
        assert @date_range.eql?(@date_range.dup)
      end

      should 'have same hash as another DateRange with the same begins_on & ends_on' do
        assert_equal @date_range.hash, @date_range.dup.hash
      end

      should 'not have same hash as a subclass of DateRange with the same begins_on & ends_on' do
        sub_class_instance = Class.new(DateRange).new(begins_on: @date_range.begins_on, ends_on: @date_range.ends_on)
        refute_equal sub_class_instance.hash, @date_range.hash
      end
    end

    context 'when range is built with begins_on & ends_on as instances of Time' do
      setup do
        @date_range = DateRange.new(begins_on: Time.parse('2000-01-01 01:01:01'), ends_on: Time.parse('2000-01-07 07:07:07'))
      end

      should 'begin on begins_on date' do
        assert_equal Date.parse('2000-01-01'), @date_range.begins_on
      end

      should 'end on ends_on date' do
        assert_equal Date.parse('2000-01-07'), @date_range.ends_on
      end
    end

    context 'when range is built with no ends_on' do
      setup do
        @date_range = DateRange.new(begins_on: Date.parse('2000-01-01'))
      end

      should 'have infinite ends_on' do
        assert @date_range.ends_on.infinite?
      end

      should 'include date far in the future' do
        assert @date_range.include?(Date.parse('9999-01-01'))
      end

      should 'have infinite number of days' do
        assert @date_range.number_of_days.infinite?
      end
    end

    context 'when range is built with no begins_on' do
      setup do
        @date_range = DateRange.new(ends_on: Date.parse('2000-01-01'))
      end

      should 'have infinite begins_on' do
        assert @date_range.begins_on.infinite?
      end

      should 'include date far in the past' do
        assert @date_range.include?(Date.parse('0000-01-01'))
      end

      should 'have infinite number of days' do
        assert @date_range.number_of_days.infinite?
      end
    end

    context 'when range includes leap day' do
      setup do
        @date_range = DateRange.new(begins_on: Date.parse('2000-01-01'), ends_on: Date.parse('2000-12-31'))
      end

      should 'include leap day' do
        assert @date_range.include?(Date.parse('2000-02-29'))
      end

      should 'count leap day in number of days' do
        assert_equal 366, @date_range.number_of_days
      end
    end
  end
end
