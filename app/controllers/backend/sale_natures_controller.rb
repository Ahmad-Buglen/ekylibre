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

class Backend::SaleNaturesController < BackendController
  manage_restfully :currency=>"Entity.of_company.currency"

  unroll

  list do |t|
    t.column :name, :url=>true
    t.column :active
    t.column :currency
    # t.column :name, :through=>:expiration, :url=>true
    # t.column :name, :through=>:payment_delay, :url=>true
    t.column :downpayment
    # t.column :downpayment_minimum
    # t.column :downpayment_percentage
    t.column :with_accounting
    t.column :name, :through=>:journal, :url=>true
    #t.column :description
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of sale natures
  def index
  end

  def show
    return unless @sale_nature = find_and_check
    t3e @sale_nature
  end

end
