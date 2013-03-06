
class CucumberPlugin
  include Locomotive::Plugin

  class << self
    attr_accessor :http_prefix
  end
  attr_accessor :greeting
  def surround_with_paragraph(str) ; "<p>#{str}</p>" ; end

  class Drop < ::Liquid::Drop
    def greeting
      obj = @context.registers[:plugin_object].greeting
    end
  end

  module Filters
    def add_http_prefix(input)
      prefix = @context.registers[:plugin_object].class.http_prefix
      if input.start_with?(prefix)
        input
      else
        "#{prefix}#{input}"
      end
    end
  end

  class Paragraph < ::Liquid::Block
    def render(context)
      obj = context.registers[:plugin_object]
      obj.surround_with_paragraph(render_all(@nodelist, context))
    end

    def render_disabled(context)
      render_all(@nodelist, context)
    end
  end

  class Newline < ::Liquid::Tag
    def render(context)
      "<br />"
    end
  end

  before_page_render :set_greeting

  def self.plugin_loaded
    self.http_prefix = 'http://'
  end

  def to_liquid
    @drop ||= Drop.new
  end
  alias :drop :to_liquid

  def config_template_file
    # Rails root is at spec/dummy
    engine_root = Rails.root.join('..', '..')
    engine_root.join('spec', 'fixtures', 'assets', 'plugin_config_template.html.haml')
  end

  def self.liquid_filters
    Filters
  end

  def self.liquid_tags
    {
      :paragraph => Paragraph,
      :newline => Newline
    }
  end

  def set_greeting
    self.greeting = 'Hello, World!'
  end

end

class FirstCucumberPlugin
  include Locomotive::Plugin

  def config_template_file
    # Rails root is at spec/dummy
    engine_root = Rails.root.join('..', '..')
    engine_root.join('spec', 'fixtures', 'assets', 'plugin_config_template.html.haml')
  end
end

class SecondCucumberPlugin
  include Locomotive::Plugin

  def config_template_file
    # Rails root is at spec/dummy
    engine_root = Rails.root.join('..', '..')
    engine_root.join('spec', 'fixtures', 'assets', 'plugin_config_template.html.haml')
  end
end
