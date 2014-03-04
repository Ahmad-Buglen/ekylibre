module Procedo
  class Variable

    attr_reader :name, :procedure, :value, :abilities, :handlers, :variety, :derivative_of, :roles, :birth_nature, :producer_name, :default_name, :destinations, :default_actor, :default_variant, :position

    def initialize(procedure, element, position)
      @procedure = procedure
      @position = position
      @name = element.attr("name").to_sym
      if element.has_attribute?("new")
        @new_variable = true
        new = element.attr("new").to_s
        unless new.match(/\A(parted\-from|produced-by)\:/)
          raise StandardError, "The new variable #{@name} in procedure #{@procedure.name} must specify where does it comes from"
        end
        new_array = new.split(/\s*\:\s*/)
        @birth_nature  = new_array.shift.underscore.to_sym
        @producer_name = new_array.shift.to_sym
      end
      @default_name = element.attr("default-name").to_s
      @default_actor   = element.has_attribute?('default-actor')   ? element.attr("default-actor").underscore.to_sym   : :none
      @default_variant = element.has_attribute?('default-variant') ? element.attr("default-variant").underscore.to_sym : :none
      # Handlers
      @handlers, @needs = [], []
      element.xpath('xmlns:handler').each do |el|
        handler = Handler.new(self, el)
        @handlers << handler
        unless @needs.include?(handler.destination)
          @needs << handler.destination
        end
      end
      hnames = @handlers.map(&:name)
      if hnames.size != hnames.uniq.size
        raise StandardError, "Duplicated handlers in #{@procedure.name}##{@name}"
      end
      if @handlers.empty?
        @needs = element.attr("need").to_s.split(/\s*\,\s*/).map(&:to_sym)
        for need in @needs
          @handlers << Handler.new(self, indicator: need)
        end
      end
      @destinations = @handlers.collect(&:destination).uniq
      @default_destinations = {}.with_indifferent_access
      for destination in @destinations
        attr_name = "default-#{destination}"
        if element.has_attribute?(attr_name)
          @default_destinations[destination] = element.attr(attr_name)
        end
      end
      @value = element.attr("value").to_s
      @abilities = element.attr("abilities").to_s.strip.split(/\s*\,\s*/)
      if element.has_attribute?("variety")
        @variety = element.attr("variety").to_s.strip 
      elsif parted?
        @variety = ":#{@producer_name}"
      end
      if element.has_attribute?("derivative-of")
        @derivative_of = element.attr("derivative-of").to_s.strip 
      elsif parted? and 
        @derivative_of = ":#{@producer_name}"
      end
      @roles = element.attr("roles").to_s.strip.split(/\s*\,\s*/)
      if element.has_attribute?("variant")
        if parted?
          raise StandardError, "'variant' attribute must be removed to limit ambiguity when new variable is parted from another"
        end
        @variant = element.attr("variant").to_s.strip
        if @variant =~ /\A\:/
          unless @procedure.variable_names.include?(@variant[1..-1].to_sym)
            raise StandardError, "Unknown variable for variant attribute: #{@variant}"
          end
        else
          unless Nomen::ProductNatureVariants[@variant]
            raise StandardError, "Unknown variant in product_nature_variants nomenclature: #{@variant}"
          end
        end
      end
    end


    # Returns the name of procedure (LOD)
    def procedure_name
      @procedure.name
    end

    # Translate the name of the variable
    def human_name
      "procedure_variables.#{name}".t(default: ["labels.#{name}".to_sym, "attributes.#{name}".to_sym, name.to_s.humanize])
    end

    def others
      @procedure.variables.values.select do |v|
        v != self
      end
    end

    #
    def handled?
      @handlers.any?
    end

    # Returns an handler by its name
    def [](name)
      @handlers.select{|h| h.name.to_s == name.to_s}.first
    end

    #
    def given?
      !@value.blank?
    end

    def needs
      @needs
    end

    def need_population?
      new? and @needs.include?(:population)
    end

    def need_shape?
      new? and @needs.include?(:shape)
    end

    def new?
      @new_variable
    end

    def parted?
      new? and @birth_nature == :parted_from
    end

    def produced?
      new? and @birth_nature == :produced_by
    end

    def default_name?
      !@default_name.blank?
    end

    def producer
      @producer ||= @procedure.variables[@producer_name]
    end

    def computed_variety
      if @variety
        if @variety =~ /\:/
          attr, other = @variety.split(/\:/)[0..1].map(&:strip)
          attr = "variety" if attr.blank?
          attr.gsub!(/\-/, "_")
          return @procedure.variables[other].send("computed_#{attr}")
        else
          return @variety
        end
      end
      return nil
    end

    def computed_derivative_of
      if @derivative_of
        if @derivative_of =~ /\:/
          attr, other = @derivative_of.split(/\:/)[0..1].map(&:strip)
          attr = "derivative_of" if attr.blank?
          attr.gsub!(/\-/, "_")
          unless variable = @procedure.variables[other]
            raise MissingVariable, "Variable #{other.inspect} can not be found"
          end
          return variable.send("computed_#{attr}")
        else
          return @derivative_of
        end
      end
      return nil
    end

    # Returns scope hash for unroll
    def scope_hash
      hash = {}
      unless @abilities.empty?
        hash[:can_each] = @abilities.join(',')
      end
      hash[:of_variety] = computed_variety if computed_variety
      hash[:derivative_of] = computed_derivative_of if computed_derivative_of
      return hash
    end


    def known_variant?
      !@variant.nil? or parted?
    end

    # Return a ProductNatureVariant based on given informations
    def variant(intervention)
      if @variant =~ /\A\:/
        other = @variant[1..-1]
        return intervention.casts.find_by(variable: other).variant
      elsif Nomen::ProductNatureVariants[@variant]
        unless variant = ProductNatureVariant.find_by(nomen: @variant.to_s)
          variant = ProductNatureVariant.import_from_nomenclature(@variant)
        end
        return variant
      end
      return nil
    end

    def variant_variable
      if parted?
        return producer
      elsif @variant =~ /\A\:/
        other = @variant[1..-1]
        return @procedure.variables[other]
      end
      return nil
    end

    def variant_indication
      if v = variant_variable
        return "same_variant_as_x".tl(x: v.human_name)
      end
      return "unknown_variant".tl
    end

    # Returns default given destination if exists
    def default(destination)
      @default_destinations[destination]
    end

    # Returns dependent variables. Variables that point on me
    def dependent_variables
      procedure.variables.values.select do |v|
        # v.producer == self or 
        v.variety =~ /\:\s*#{self.name}\z/ or v.derivative_of =~ /\:\s*#{self.name}\z/
      end
    end

    # Returns dependings variables. Variables that I point
    def depending_variables
      # self.producer
      [procedure.variables[self.variety.split(/\:\s*/)], procedure.variables[self.derivative_of.split(/\:\s*/)]].compact
    end

  end
end
