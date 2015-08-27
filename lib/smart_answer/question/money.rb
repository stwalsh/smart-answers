module SmartAnswer
  module Question
    class Money < Base
      def parse_input(raw_input, state)
        SmartAnswer::Money.new(raw_input)
      end
    end
  end
end
