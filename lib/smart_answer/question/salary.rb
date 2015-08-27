module SmartAnswer
  module Question
    class Salary < Base
      def parse_input(raw_input, state)
        SmartAnswer::Salary.new(raw_input)
      end

      def to_response(input)
        salary = parse_input(input, state = nil)
        {
          amount: salary.amount,
          period: salary.period
        }
      rescue
        nil
      end
    end
  end
end
