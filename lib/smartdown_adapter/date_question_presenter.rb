module SmartdownAdapter
  class DateQuestionPresenter < SmartdownAdapter::QuestionPresenter
    #TODO: range should be specified in smartdown and taken from there
    #these are only defaults
    #in the future we will want to specify in smartdown start/end etc,,,
    def defaulted_day?
      false
    end

    def defaulted_month?
      false
    end

    def defaulted_year?
      false
    end

    def default
      Date.today
    end

    def start_date
      1.year.ago
    end

    def end_date
      3.years.from_now
    end

    def to_response(input)
        date = ::Date.parse(input)
        {
          day: date.day,
          month: date.month,
          year: date.year
        }
      rescue
        nil
      end
  end
end