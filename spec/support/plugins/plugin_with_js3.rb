class PluginWithJS3
  include Locomotive::Plugin

  def self.javascript_context
    {
      variable: Locomotive::Plugins::Variable.new { "string" },
      method: lambda{|this,word,times| word*times}
    }
  end
end
