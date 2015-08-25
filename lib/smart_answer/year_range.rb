module SmartAnswer
  class YearRange < DateRange
    class << self
      def class_for_years_beginning(month:, day:)
        klass = Class.new(self) do
          cattr_accessor :month, :day

          def initialize(begins_in:)
            super(begins_on: Date.new(begins_in, month, day))
          end
        end
        klass.month, klass.day = month, day
        klass
      end

      def current
        on(Date.today)
      end

      def on(date)
        year = new(begins_in: date.year)
        year.include?(date) ? year : year.previous
      end
    end

    def initialize(begins_on:)
      super(begins_on: begins_on, ends_on: begins_on.to_date + 1.year - 1)
    end

    def previous
      self.class.new(begins_in: begins_on.year - 1)
    end
  end
end
