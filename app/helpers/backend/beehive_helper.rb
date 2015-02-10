# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2015 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend::BeehiveHelper

  FORMAT_VERSION = 1

  # 巣 Beehive permits to create modular interface organized in cells
  def beehive(name = nil, &block)
    html = ""
    # return html unless block_given?
    name ||= "#{controller_name}_#{action_name}".to_sym
    board = Beehive.new(name, self)
    if block_given?
      if block.arity < 1
        board.instance_eval(&block)
      else
        block[board]
      end
    end
    layout = board.to_hash
    if preference = current_user.preferences.find_by(name: board.preference_name)
      got = YAML.load(preference.value).deep_symbolize_keys
      layout = got if got[:version] and got[:version] >= FORMAT_VERSION
    end
    return render(partial: "backend/shared/beehive", object: board, locals: {layout: layout})
  end

  class Beehive

    class Box < Array
      def self.short_name
        "box"
      end

      def to_hash
        { cells: map(&:to_hash) }
      end
    end

    class Cell
      attr_reader :content, :type, :options, :name

      cattr_reader :controller_types
      def self.controller_types
        unless @controller_types
          Dir.chdir(Rails.root.join('app/controllers/backend/cells')) do
            @controller_types = Dir["*_controller.rb"].map do |path|
              path.gsub(/_cells_controller.rb$/, '').to_sym
            end.compact
          end
        end
        return @controller_types
      end

      def initialize(name, options = {})
        unless name.is_a?(Symbol)
          raise "Only symbol for cell name. Use :title option to specify title."
        end
        @name = name.to_sym
        @options = options
        @type = @options.delete(:type) || @name
        @has_content = @options.has_key?(:content)
        @content = @options.delete(:content)
        @i18n = @options.delete(:i18n) || @options
        if self.class.controller_types.include?(@type)
          if content?
            raise "Local type cannot be: #{@type}. Already taken."
          end
        elsif !content?
          raise "Invalid cell. Need content or a valid controller cell name (Not #{@name} alone)"
        end
      end

      def content?
        @has_content
      end

      def title
        @options[:title].is_a?(Symbol) ? @options[:title].tl(@i18n.merge(default: @name.to_s.humanize)) : (@options[:title] || @name.tl(@i18n.merge(default: @name.to_s.humanize)))
      end

      def to_hash
        @options.merge(name: @name.to_s, type: @type.to_s)
      end

    end


    attr_reader :name, :boxes

    def initialize(name, template)
      @name = name
      @boxes = []
      @cells = {}.with_indifferent_access
      @current_box = nil
      @template = template
    end

    # Adds a cell in the beehive
    # Adds a box too if not defined
    def cell(name = :details, options = {}, &block)
      if @current_box
        if block_given?
          options[:content] = @template.capture(&block)
        end
        if @cells.keys.include? name.to_s
          raise StandardError, "A cell with a given name (#{name}) has already been given."
        end
        c = Cell.new(name, options)
        @cells[name] = c
        @current_box << c
      else
        hbox do
          cell(name, options, &block)
        end
      end
    end

    def hbox(&block)
      return box(&block)
    end

    def to_hash
      { version: FORMAT_VERSION, boxes: @boxes.map(&:to_hash) }
    end

    def id
      "beehive-#{@name}"
    end

    def preference_name
      "beehive.#{@name}"
    end

    def find_cell(name)
      @cells[name]
    end

    def local_cells
      @cells.values # .select{|c| c.content? }
    end

    def available_cells
      return (Cell.controller_types + @cells.keys).map(&:to_s).map do |x|
        [x.tl, x]
      end.sort do |a,b|
        a.first.ascii <=> b.first.ascii
      end
    end

    protected

    def box(&block)
      if @current_box
        raise StandardError, "Cannot define box in other box"
      end
      old_current_box = @current_box
      if block_given?
        @current_box = Box.new
        block[self]
        @boxes << @current_box unless @current_box.empty?
      end
      @current_box = old_current_box
    end

  end

end
