module Procedo

  class Operation
    attr_reader :id, :procedure, :tasks, :duration

    def initialize(procedure, element)
      @procedure = procedure
      if element.has_attribute?('id')
        @id = element.attr('id').to_s
      else
        raise Procedo::Errors::MissingAttribute.new("Each operation must have an id attribute (which must be a decimal integer). In: #{@procedure.signature}.")
      end
      if element.has_attribute?('duration')
        expr = element.attr('duration').to_s.strip.split(/\s+/)
        @duration = expr.first.to_d.send(expr.second)
      end
      @tasks = HashWithIndifferentAccess.new
      element.xpath('xmlns:task').each_with_index do |task, index|
        key = index.to_s
        @tasks[key] = Task.new(self, key, task)
      end
    end


    def no_duration?
      @duration.nil?
    end

    def human_name
      "Operation ##{self.id}"
    end

    # Returns an array of humanized expression
    def human_expressions
      return @tasks.values.map(&:human_expression)
    end

    def name
      @id.to_s
    end

    def uid
      self.procedure.uid + "-" + @id.to_s
    end

  end

end
