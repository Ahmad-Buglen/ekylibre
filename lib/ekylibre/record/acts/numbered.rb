module Ekylibre::Record
  module Acts #:nodoc:
    module Numbered #:nodoc:

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Use preference to select preferred sequence to attribute number
        # in column
        def acts_as_numbered(column = :number, options = {})
          # Bugs with MSSQL
          # raise ArgumentError.new("Method #{column.inspect} must be an existent column of the table #{self.table_name}") unless self.columns_hash.has_key? column.to_s
          options = {:start => '00000001'}.merge(options)

          main_class = self
          while main_class.superclass != Ekylibre::Record::Base and main_class.superclass != ActiveRecord::Base
            main_class = self.superclass
          end
          class_name = main_class.name

          sequence = options[:sequence] || class_name.tableize # "#{self.name.underscore.pluralize}_sequence"

          last  = "#{class_name}.where('#{column} IS NOT NULL').reorder('LENGTH(#{column}) DESC, #{column} DESC').first"

          code  = ""

          code << "attr_readonly :#{column}\n" unless options[:readonly].is_a? FalseClass

          code << "validates :#{column}, :presence => true, :uniqueness => true\n"

          code << "before_validation(:load_unique_predictable_#{column}, :on => :create)\n"
          code << "after_validation(:load_unique_reliable_#{column}, :on => :create)\n"

          code << "def load_unique_predictable_#{column}\n"
          code << "  last = #{last}\n"
          code << "  self.#{column} = (last.nil? ? #{options[:start].inspect} : last.#{column}.blank? ? #{options[:start].inspect} : last.#{column}.succ)\n"
          code << "  while #{class_name}.where(:#{column} => self.#{column}).count > 0 do\n"
          code << "    self.#{column}.succ!\n"
          code << "  end\n"
          code << "  return true\n"
          code << "end\n"


          code << "def load_unique_reliable_#{column}\n"
          code << "  if sequence = Sequence.of('#{sequence}')\n"
          code << "    self.#{column} = sequence.next_value\n"
          code << "    while #{class_name}.where(:#{column} => self.#{column}).count > 0 do\n"
          code << "      self.#{column} = sequence.next_value\n"
          code << "    end\n"
          code << "  else\n"
          code << "    last = #{last}\n"
          code << "    self.#{column} = (last.nil? ? #{options[:start].inspect} : last.#{column}.blank? ? #{options[:start].inspect} : last.#{column}.succ)\n"
          code << "  end\n"
          code << "  return true\n"
          code << "end\n"
          # puts code
          class_eval code
        end
      end

    end
  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Acts::Numbered)
