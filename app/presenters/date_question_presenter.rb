class DateQuestionPresenter < QuestionPresenter
  def response_label(value)
    I18n.localize(value, format: :long)
  end

  def start_date
    @node.range(@state) == false ? 1.year.ago : @node.range(@state).begin
  end

  def end_date
    @node.range(@state) == false ? 3.years.from_now : @node.range(@state).end
  end
end
