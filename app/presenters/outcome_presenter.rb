class OutcomePresenter < NodePresenter
  def initialize(i18n_prefix, node, state = nil, options = {})
    @options = options
    super(i18n_prefix, node, state)
    @view = ActionView::Base.new([template_directory])
    @view.extend(SmartAnswer::OutcomeHelper)
    @view.extend(SmartAnswer::OverseasPassportsHelper)
    @view.extend(SmartAnswer::MarriageAbroadHelper)
    @rendered_erb_template = false
  end

  def title
    if title_erb_template_exists?
      render_erb_template
      title = @view.content_for(:title) || ''
      strip_leading_spaces(title.chomp)
    end
  end

  def body(html: true)
    if body_erb_template_exists?
      render_erb_template
      govspeak = @view.content_for(:body) || ''
      govspeak = strip_leading_spaces(govspeak.to_str)
      govspeak = strip_extra_blank_lines(govspeak)
      html ? GovspeakPresenter.new(govspeak).html : govspeak
    end
  end

  def next_steps(html: true)
    if next_steps_erb_template_exists?
      render_erb_template
      govspeak = @view.content_for(:next_steps) || ''
      govspeak = strip_leading_spaces(govspeak.to_str)
      govspeak = strip_extra_blank_lines(govspeak)
      html ? GovspeakPresenter.new(govspeak).html : govspeak
    end
  end

  def erb_template_path
    template_directory.join(erb_template_name)
  end

  def erb_template_name
    "#{name}.govspeak.erb"
  end

  private

  def template_directory
    @options[:erb_template_directory] || @node.template_directory
  end

  def title_erb_template_exists?
    erb_template_exists? && has_content_for_title?
  end

  def body_erb_template_exists?
    erb_template_exists? && has_content_for_body?
  end

  def next_steps_erb_template_exists?
    erb_template_exists? && has_content_for_next_steps?
  end

  def erb_template_exists?
    File.exists?(erb_template_path)
  end

  def render_erb_template
    unless @rendered_erb_template
      @view.render(template: erb_template_name, locals: @state.to_hash)
      @rendered_erb_template = true
    end
  end

  def has_content_for_body?
    File.read(erb_template_path) =~ /content_for :body/
  end

  def has_content_for_title?
    File.read(erb_template_path) =~ /content_for :title/
  end

  def has_content_for_next_steps?
    File.read(erb_template_path) =~ /content_for :next_steps/
  end

  def strip_leading_spaces(string)
    string.gsub(/^ +/, '')
  end

  def strip_extra_blank_lines(string)
    string.gsub(/(\n$){2,}/m, "\n")
  end
end
