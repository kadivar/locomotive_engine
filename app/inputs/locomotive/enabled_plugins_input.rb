module Locomotive
  class EnabledPluginsInput < ::Formtastic::Inputs::CheckBoxesInput

    def to_html
      input_wrapping do
        label_html = ''
        choices_group_wrapping do
          collection.map { |choice|
            choice_wrapping(choice_wrapping_html_options(choice)) do
              choice_html(choice)
            end
          }.join("\n").html_safe
        end
      end
    end

    def choices_group_wrapping(&block)
      template.content_tag(:div,
        template.capture(&block),
        choices_group_wrapping_html_options
      )
    end

    def choice_wrapping(html_options, &block)
      template.content_tag(:div,
        template.capture(&block),
        html_options
      )
    end

    def choice_html(choice)
      check_box_without_hidden_input(choice) <<
      template.content_tag(:label,
        choice_label(choice),
        label_html_options.merge(:for => choice_input_dom_id(choice), :class => nil)
      )
    end

    def choice_label(choice)
      choice.humanize
    end

    def choices_group_wrapping_html_options
      { :class => 'list' }
    end

    def choice_wrapping_html_options(choice)
      super.tap do |options|
        options[:class] = "entry #{checked?(choice) ? 'selected' : ''}"
      end
    end

    def hidden_fields?
      false
    end

    def check_box_without_hidden_input(choice)
      value = choice_value(choice)
      template.check_box_tag(
        input_name,
        value,
        checked?(value),
        input_html_options.merge(:id => choice_input_dom_id(choice), :disabled => disabled?(value), :required => false)
      )
    end

    def input_name
      if builder.options.key?(:index)
        "#{object_name}[#{builder.options[:index]}][#{association_primary_key || method}][][plugin_id]"
      else
        "#{object_name}[#{association_primary_key || method}][][plugin_id]"
      end
    end

    def association_primary_key
      # FIXME: this is a bit of a hack
      method
    end

    def selected_values
      @selected_values ||= make_selected_values
    end

    protected

    def make_selected_values
      ret = (if object.respond_to?(method)
        object.send(method).collect(&:plugin_id).compact.flatten
      else
        []
      end)
      ret
    end

  end
end
