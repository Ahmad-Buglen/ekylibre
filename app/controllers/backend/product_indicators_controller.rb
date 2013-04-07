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

class Backend::ProductIndicatorsController < BackendController
  manage_restfully :redirect_to => '(@product_indicator.choice? ? {:action => :show, :id => "id"} : :back)'
  manage_restfully_list
  unroll_all

  list(:order => "name") do |t|
    t.column :usage
    t.column :name, :url => true
    t.column :nature
    t.column :active
    t.column :choices_count, :datatype => :integer
    t.action :up, :method => :post#, :unless => :first?
    t.action :down, :method => :post#, :unless => :last?
    t.action :edit
    t.action :show, :image => :menulist, :if => :choice?
  end

  # Displays the main page with the list of custom fields
  def index
  end

  list(:choices, :model => :product_indicator_choices, :conditions => {:nature_id => ['session[:current_product_indicator_id]']}, :order => 'position') do |t|
    t.column :name
    t.column :value
    t.action :up, :unless => :first?, :method => :post
    t.action :down, :unless => :last?, :method => :post
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays details of one custom field selected with +params[:id]+
  def show
    return unless @product_indicator = find_and_check(:product_indicator)
    session[:current_product_indicator_id] = @product_indicator.id
    t3e @product_indicator.attributes
  end

  # Sort all choices by name
  def sort
    return unless @product_indicator = find_and_check
    @product_indicator.sort_choices!
    redirect_to_current
  end

end
