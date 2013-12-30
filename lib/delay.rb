# -*- coding: utf-8 -*-
class InvalidDelayExpression < ArgumentError
end


# Delay permits to define explicit and complex delays
# Delay are not always linears due to BOM/EOM, so if D3 = D1 + D2 is true, D1 = D2 - D3 is not always true.
class Delay
  SEPARATOR = ','.freeze
  TRANSLATIONS = {
    'an' => :year,
    'ans' => :year,
    'année' => :year,
    'années' => :year,
    'annee' => :year,
    'annees' => :year,
    'year' => :year,
    'years' => :year,
    'mois' => :month,
    'month' => :month,
    'months' => :month,
    'week' => :week,
    'semaine' => :week,
    'weeks' => :week,
    'semaines' => :week,
    'jour' => :day,
    'day' => :day,
    'jours' => :day,
    'days' => :day,
    'heure' => :hour,
    'hour' => :hour,
    'heures' => :hour,
    'hours' => :hour,
    'minute' => :minute,
    'minutes' => :minute,
    'seconde' => :second,
    'second' => :second,
    'secondes' => :second,
    'seconds' => :second
  }
  KEYS = TRANSLATIONS.keys.join("|").freeze

  attr_reader :expression

  def initialize(expression = nil)
    base = (expression.nil? ? nil : expression.dup)
    expression ||= []
    expression = expression.to_s.strip.split(/\s*\,\s*/) if expression.is_a?(String)
    raise ArgumentError.new("String or Array expected (got #{expression.class.name}:#{expression.inspect})") unless expression.is_a?(Array)
    @expression = expression.collect do |step|
      # step = step.mb_chars.downcase
      if step.match(/\A(eom|end of month|fdm|fin de mois)\z/)
        [:eom]
      elsif step.match(/\A(bom|beginning of month|ddm|debut de mois|début de mois)\z/)
        [:bom]
      elsif step.match(/\A\d+\ (#{KEYS})(\ (avant|ago))?\z/)
        words = step.split(/\s+/).map(&:to_s)
        if TRANSLATIONS[words[1]].nil?
          raise InvalidDelayExpression.new("#{words[1].inspect} is an undefined period (#{step.inspect} of #{base.inspect})")
        end
        [TRANSLATIONS[words[1]] , (words[2].blank? ? 1 : -1) * words[0].to_i]
      elsif !step.blank?
        raise InvalidDelayExpression.new("#{step.inspect} is an invalid step. (From #{base.inspect} => #{expression.inspect})")
      end
    end
  end

  def compute(started_at = Time.now)
    return nil if started_at.nil?
    stopped_at = started_at.dup
    @expression.each do |step|
      case step[0]
      when :eom
        stopped_at = stopped_at.end_of_month
      when :bom
        stopped_at = stopped_at.beginning_of_month
      else
        stopped_at += step[1].send(step[0])
      end
    end
    return stopped_at
  end

  def inspect
    return @expression.collect do |step|
      (step.size == 1 ? step[0].to_s.upcase : step[1].to_s + " " + step[0].to_s+"s")
    end.join(", ")
  end

  def to_s
    return self.inspect
  end

  # Invert steps :
  #   * EOM -> BOM
  #   * BOM -> EOM
  #   * x <duration> -> x <duration> ago
  def invert!
    @expression = @expression.collect do |step|
      if step == :eom
        :bom
      elsif step == :bom
        :eom
      else
        [step.first,  -step.second]
      end
    end
    return self
  end

  # Return a duplicated inverted copy
  def invert
    self.dup.invert!
  end


  # Sums delays
  def +(delay)
    if delay.is_a?(Delay)
      Delay.new(self.to_s + ", " + delay.to_s)
    elsif delay.is_a?(String)
      Delay.new(self.to_s + ", " + Delay.new(delay).to_s)
    elsif delay.is_a?(Numeric)
      Delay.new(self.to_s + ", " + delay.to_s + " seconds")
    elsif delay.is_a?(Measure) and delay.dimension == :time and [:second, :minute, :hour, :day, :month, :year].include? delay.unit
      Delay.new(self.to_s + ", " + delay.value.to_s + " " + delay.unit.to_s)
    else
      raise ArgumentError.new("Cannot sum #{delay.class.name} to a #{self.class.name}")
    end
  end

  # Adds opposites values of given delay
  def -(delay)
    if delay.is_a?(Delay)
      Delay.new(self.to_s + ", " + delay.opposite.to_s)
    elsif delay.is_a?(String)
      Delay.new(self.to_s + ", " + Delay.new(delay).opposite.to_s)
    elsif delay.is_a?(Numeric)
      Delay.new(self.to_s + ", " + delay.to_s + " seconds")
    elsif delay.is_a?(Measure) and delay.dimension == :time and [:second, :minute, :hour, :day, :month, :year].include? delay.unit
      Delay.new(self.to_s + ", " + delay.value.to_s + " " + delay.unit.to_s + " ago")
    else
      raise ArgumentError.new("Cannot sum #{delay.class.name} to a #{self.class.name}")
    end
  end

end



module ValidatesDelayFormat

  module Validator
    class DelayFormatValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        begin
          Delay.new(value)
        rescue InvalidDelayExpression => e
          record.errors.add(attributes, :invalid, options.merge(:value => value))
        end
      end
    end
  end

  module ClassMethods
    def validates_delay_format_of(*attr_names)
      for attr_name in attr_names
        validate attr_name, delay: true
      end
      # validates_with ActiveRecord::Base::DelayFormatValidator, *attr_names
    end
  end

end
# include InstanceMethods to expose the ExistenceValidator class to ActiveModel::Validations
ActiveRecord::Base.send(:include, ValidatesDelayFormat::Validator)

# extend the ClassMethods to expose the validates_presence_of method as a class level method of ActiveModel::Validations
ActiveRecord::Base.send(:extend, ValidatesDelayFormat::ClassMethods)
