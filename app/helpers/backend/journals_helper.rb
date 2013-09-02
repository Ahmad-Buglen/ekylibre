# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend::JournalsHelper

  def journals_tag
    render :partial => "backend/journals/index"
  end

  # Show the 3 modes of view for a journal
  def journal_view_tag
    code = content_tag(:dt, tg(:view))
    for mode in controller.journal_views
      code << content_tag(:dd, link_to(h("journal_view.#{mode}".tl(:default => ["labels.#{mode}".to_sym, mode.to_s.humanize])), params.merge(:view => mode)), (@journal_view == mode ? {:class => :active} : nil)) # content_tag(:i) + " " +
    end
    return content_tag(:dl, code, :id => "journal-views")
  end

  # Create a widget with all the possible periods
  def journal_period_crit(*args)
    options = (args[-1].is_a?(Hash) ? args.delete_at(-1) : {})
    name = args.shift || :period
    value = args.shift
    configuration = {:custom => :interval}.merge(options)
    configuration[:id] ||= name.to_s.gsub(/\W+/, '_').gsub(/(^_|_$)/, '')
    value ||= params[name] || options[:default]
    list = []
    list << [tc(:all_periods), "all"]
    for year in FinancialYear.reorder("started_on DESC")
      list << [year.code, year.started_on.to_s << "_" << year.stopped_on.to_s]
      list2 = []
      date = year.started_on
      while date < year.stopped_on and date < Date.today
        date2 = date.end_of_month
        list2 << [tc(:month_period, :year => date.year, :month => t("date.month_names")[date.month], :code => year.code), date.to_s << "_" << date2.to_s]
        date = date2 + 1
      end
      list += list2.reverse
    end
    code = ""
    code << content_tag(:label, options[:label] || tc(:period), :for => configuration[:id]) + " "
    fy = FinancialYear.current
    params[:period] = value = value || :all # (fy ? fy.started_on.to_s + "_" + fy.stopped_on.to_s : :all)
    custom_id = "#{configuration[:id]}_#{configuration[:custom]}"
    toggle_method = "toggle#{custom_id.camelcase}"
    if configuration[:custom]
      params[:started_on] = params[:started_on].to_date rescue (fy ? fy.started_on : Date.today)
      params[:stopped_on] = params[:stopped_on].to_date rescue (fy ? fy.stopped_on : Date.today)
      params[:stopped_on] = params[:started_on] if params[:started_on] > params[:stopped_on]
      list.insert(0, [tc(configuration[:custom]), configuration[:custom]])
    end

    if replacement = options.delete(:include_blank)
      list.insert(0, [(replacement.is_a?(Symbol) ? tl(replacement) : replacement.to_s), ""])
    end

    code << select_tag(name, options_for_select(list, value), :id => configuration[:id], "data-show-value" => "##{configuration[:id]}_")

    if configuration[:custom]
      code << " " << content_tag(:span, tc(:manual_period, :start => date_field_tag(:started_on, params[:started_on], :size => 10), :finish => date_field_tag(:stopped_on, params[:stopped_on], :size => 10)).html_safe, :id => custom_id)
    end
    return code.html_safe
  end

  # Create a widget to select states of entries (and entry items)
  def journal_entries_states_crit
    code = ""
    code << content_tag(:label, tc(:journal_entries_states))
    states = JournalEntry.states
    params[:states] = {} unless params[:states].is_a? Hash
    no_state = !states.detect{|x| params[:states].has_key?(x)}
    for state in states
      key = state.to_s
      name, id = "states[#{key}]", "states_#{key}"
      if active = (params[:states][key]=="1" or no_state)
        params[:states][key] = "1"
      else
        params[:states].delete(key)
      end
      code << " " << check_box_tag(name, "1", active, :id => id)
      code << " " << content_tag(:label, JournalEntry.state_label(state), :for => id)
    end
    return code.html_safe
  end

  # Create a widget to select some journals
  def journals_crit
    code, field = "", :journals
    code << content_tag(:label, Backend::JournalsController.human_name)
    journals = Journal.all
    params[field] = {} unless params[field].is_a? Hash
    no_journal = !journals.detect{|x| params[field].has_key?(x.id.to_s)}
    for journal in journals
      key = journal.id.to_s
      name, id = "#{field}[#{key}]", "#{field}_#{key}"
      if active = (params[field][key] == "1" or no_journal)
        params[field][key] = "1"
      else
        params[field].delete(key)
      end
      code << " " << check_box_tag(name, "1", active, :id => id)
      code << " " << content_tag(:label, journal.name, :for => id)
    end
    return code.html_safe
  end



end
