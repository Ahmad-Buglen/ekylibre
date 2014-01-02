# encoding: utf-8
module Ekylibre

  module Modules

    class ReverseImpossible < StandardError
    end

    def self.file
      Rails.root.join("config", "modules.xml")
    end

    mattr_reader :hash, :reversions, :icons
    @@reversions = {}
    @@icons = ActiveSupport::OrderedHash.new
    File.open(file) do |f|
      doc = Nokogiri::XML(f) do |config|
        config.strict.nonet.noblanks
      end
      @@hash = doc.xpath('/modules/module').inject(ActiveSupport::OrderedHash.new) do |modules, element|
        module_name = element.attr("name").to_s.to_sym
        @@icons[module_name] = {:children => ActiveSupport::OrderedHash.new}
        @@icons[module_name][:icon] = element.attr("icon").to_s if element.attr("icon")
        modules[module_name] = element.xpath('group').inject(ActiveSupport::OrderedHash.new) do |groups, elem|
          group_name = elem.attr("name").to_s.to_sym
          @@icons[module_name][:children][group_name] = {:children => ActiveSupport::OrderedHash.new}
          @@icons[module_name][:children][group_name][:icon] = elem.attr("icon").to_s if elem.attr("icon")
          groups[group_name] = elem.xpath('item').inject(ActiveSupport::OrderedHash.new) do |items, e|
            item_name = e.attr("name")
            @@icons[module_name][:children][group_name][:children][item_name] = {:children => []}
            @@icons[module_name][:children][group_name][:children][item_name][:icon] = e.attr("icon").to_s if e.attr("icon")
            items[item_name] = e.xpath('page').collect do |p|
              url = p.attr("to").to_s.split('#')
              @@reversions[url[0]] ||= {}
              @@reversions[url[0]][url[1]] = [module_name, group_name, item_name]
              @@icons[module_name][:children][group_name][:children][item_name][:children] << {:controller => url[0], :action => url[1]}
              {:controller => "/" + url[0], :action => url[1]}
            end
            items
          end
          groups
        end
        modules
      end
    end

    # Returns the path (module, group, item) from an action
    def self.reverse(controller, action)
      path = nil
      if reversions[controller]
        path = reversions[controller][action.to_s]
      end
      return path
    end

    # Returns the path (module, group, item) from an action
    def self.reverse!(controller, action)
      unless path = self.reverse(controller, action)
        raise ReverseImpossible, "Cannot reverse action #{controller}##{action}"
      end
      return path
    end

    # Returns the name of the module corresponding to an URL
    def self.module_of(controller, action)
      return action.to_sym if controller.to_s == "backend/dashboards"
      if r = reverse(controller, action)
        return r[0]
      end
      return nil
    end

    # Returns the name of the group corresponding to an URL
    def self.group_of(controller, action)
      return reverse(controller, action)[1]
    end

    # Returns the name of the item corresponding to an URL
    def self.item_of(controller, action)
      return reverse(controller, action)[2]
    end

    # Returns the group hash corresponding to the current module
    def self.groups_of(controller, action)
      return hash[module_of(controller, action)] || {}
    end

    # Reutns the group hash corresponding to the module
    def self.groups_in(mod)
      return hash[mod] || {}
    end

    # Returns a human name corresponding to the arguments
    # 1: module
    # 2: group
    # 3: item
    def self.human_name(*args)
      levels = [nil, :module, :group, :item]
      return self.send("#{levels[args.count]}_human_name", *args)
    end

    # Returns the human name of a group
    def self.module_human_name(mod)
      ::I18n.translate("menus.#{mod}".to_sym, default: ["labels.menus.#{mod}".to_sym, "labels.#{mod}".to_sym])
    end

    # Returns the human name of a group
    def self.group_human_name(mod, group)
      ::I18n.translate(("menus." + [mod, group].join(".")).to_sym, default: ["menus.#{group}".to_sym, "labels.menus.#{group}".to_sym, "labels.#{group}".to_sym])
    end

    # Returns the human name of an item
    def self.item_human_name(mod, group, item)
      p = hash[mod][group][item].first
      ::I18n.translate(("menus." + [mod, group, item].join(".")).to_sym, default: ["menus.#{item}".to_sym, "labels.menus.#{item}".to_sym, "actions.#{p[:controller][1..-1]}.#{p[:action]}".to_sym, "labels.#{item}".to_sym])
    end


    def self.icon(*args)
      arg = args.shift
      h = @@icons[arg]
      while args.size > 0
        arg = args.shift
        h = h[:children][arg]
      end
      return h[:icon] || arg
    end

  end

end
