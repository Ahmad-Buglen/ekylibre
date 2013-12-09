module PeriodicCalculable
  extend ActiveSupport::Concern

  PARAMETERS = [:period, :at, :name, :column]

  included do
    class_attribute *(PARAMETERS.map{|p| "default_calculable_#{p}"})
    # self.default_calculable_column = :id
    self.default_calculable_period = :month
    self.default_calculable_at = :created_at
  end

  module ClassMethods

    def calculable(options = {})
      for parameter in PeriodicCalculable::PARAMETERS
        if options[parameter]
          self.send("default_calculable_#{parameter}=", options[parameter])
        end
      end
    end

    def averages_of_periods(options = {})
      self.calculate_in_periods(:avg, {name: :average}.merge(options))
    end

    def sums_of_periods(options = {})
      self.calculate_in_periods(:sum, {name: :sum}.merge(options))
    end

    def counts_of_periods(options = {})
      self.calculate_in_periods(:count, {name: :count}.merge(options))
    end

    def calculate_in_periods(operation, options = {})
      column = options[:column] || default_calculable_column
      options[:name] ||= default_calculable_name || column || operation
      options[:period] ||= default_calculable_period
      options[:period] = :doy if options[:period] == :day
      options[:at] ||= default_calculable_at
      expr = "EXTRACT(YEAR FROM #{self.table_name}.#{options[:at]})*1000 + EXTRACT(#{options[:period]} FROM #{self.table_name}.#{options[:at]})"
      group(expr).reorder(expr).select("#{expr} AS expr, #{operation}(#{self.table_name}.#{column}) AS #{options[:name]}")
    end

  end
end
