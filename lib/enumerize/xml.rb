module Enumerize
  class Value

    def to_xml(options = {})
      require 'active_support/builder' unless defined?(Builder)

      options = options.dup
      options[:indent]  ||= 2
      options[:root]    ||= "hash"
      options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

      builder = options[:builder]
      builder.instruct! unless options.delete(:skip_instruct)

      root = ActiveSupport::XmlMini.rename_key(options[:root].to_s, options)

      builder.__send__(:method_missing, root, :name => self.to_s) do
        self.text.to_s
      end
    end

  end
end
