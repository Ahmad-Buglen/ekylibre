module Ekylibre::Record  #:nodoc:
  module Bookkeep
    def self.actions
      [:create, :update, :destroy]
    end

    class Base
      attr_reader :resource, :action, :draft

      cattr_reader :id
      @@id = "0"

      def self.next_id
        @@id.succ!
        return @@id
      end

      def initialize(resource, action, draft)
        raise ArgumentError.new("Unvalid action #{action.inspect} (#{Ekylibre::Record::Bookkeep::actions.to_sentence} are accepted)") unless Ekylibre::Record::Bookkeep::actions.include? action
        @resource = resource
        @action = action
        @draft = draft
      end



      def journal_entry(journal, options={}, &block)
        column = options.delete(:column) || :journal_entry_id
        condition = (options.has_key?(:if) ? options.delete(:if) : !options.delete(:unless))

        attributes = options
        attributes[:resource]   ||= @resource
        # attributes[:state]      ||= @state
        attributes[:printed_at] ||= @resource.created_at if @resource.respond_to? :created_at
        unless attributes[:printed_at].is_a?(Time)
          raise ArgumentError, "Time of journal_entry (printed_at) must be given. Time expected, got #{attributes[:printed_at].class.name} (#{attributes[:printed_at].inspect})"
        end
        if condition
          unless journal.is_a? Journal
            raise ArgumentError, "Unknown journal: (#{journal.inspect})"
          end
          attributes[:journal_id] = journal.id
        end

        Ekylibre::Record::Base.transaction do
          if journal_entry = JournalEntry.find_by(id: @resource.send(column))
            # Cancel the existing journal_entry
            if journal_entry.draft? and condition and (attributes[:journal_id] == journal_entry.journal_id)
              journal_entry.items.destroy_all
              journal_entry.reload
              journal_entry.update_attributes!(attributes)
            else
              journal_entry.cancel
              journal_entry = nil
            end
          end

          # Add journal items
          if block_given? and condition and @action != :destroy
            journal_entry ||= JournalEntry.create!(attributes)
            yield(journal_entry)
            journal_entry.reload.confirm unless @draft
          end

          # Set accounted columns
          @resource.class.where(:id => @resource.id).update_all(:accounted_at => Time.now, column => (journal_entry ? journal_entry.id : nil))
        end
      end


    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def bookkeep(options = {}, &block)
        raise ArgumentError.new("No given block") unless block_given?
        raise ArgumentError.new("Wrong number of arguments (#{block.arity} for 1)") unless block.arity == 1
        configuration = {on: Ekylibre::Record::Bookkeep::actions, column: :accounted_at, method_name: __method__ }
        configuration.update(options) if options.is_a?(Hash)
        configuration[:column] = configuration[:column].to_s
        method_name = configuration[:method_name].to_s
        core_method_name ||= "_#{method_name}_#{Ekylibre::Record::Bookkeep::Base.next_id}"

        unless columns_definition[configuration[:column]]
          Rails.logger.fatal "#{configuration[:column]} is needed for #{self.name}::bookkeep"
          # raise StandardError, "#{configuration[:column]} is needed for #{self.name}::bookkeep"
        end

        code  = "include Ekylibre::Record::Bookkeep::InstanceMethods\n"

        code << "def #{method_name}(action = :create, draft = nil)\n"
        code << "  draft = ::Preference[:bookkeep_in_draft] if draft.nil?\n"
        code << "  self.#{core_method_name}(Ekylibre::Record::Bookkeep::Base.new(self, action, draft))\n"
        code << "  self.class.where(id: self.id).update_all(#{configuration[:column]}: Time.now)\n"
        code << "end\n"

        configuration[:on] = [configuration[:on]].flatten
        for action in Ekylibre::Record::Bookkeep::actions
          if configuration[:on].include? action
            code << "after_#{action} do \n"
            code << "  if ::Preference[:bookkeep_automatically]\n"
            code << "    self.#{method_name}(:#{action}, ::Preference[:bookkeep_in_draft])\n"
            code << "  end\n"
            code << "end\n"
          end
        end

        class_eval code

        self.send(:define_method, core_method_name, &block)
      end

    end

    module InstanceMethods
      def accounted?
        not self.accounted_at.nil?
      end
    end

  end
end
Ekylibre::Record::Base.send(:include, Ekylibre::Record::Bookkeep)
