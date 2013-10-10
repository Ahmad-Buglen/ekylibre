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

class Backend::OutgoingDeliveriesController < BackendController

  manage_restfully

  unroll

  list(:conditions => search_conditions(:outgoing_deliveries => [:number, :reference_number, :weight], :entities => [:full_name, :code])) do |t|
    t.column :number, url: true
    t.column :transport, url: true
    t.column :transporter, url: true
    t.column :reference_number
    t.column :sent_at
    #t.column :moved_on
    t.column :mode
    #t.column :number, through: :sale, url: true
    t.column :weight
    #t.column :amount
    t.action :edit
    t.action :destroy
  end

  list(:items, :model => :outgoing_delivery_items, :conditions => {:delivery_id => 'params[:id]'.c}) do |t|
    t.column :product, url: true
    t.column :product_work_number, through: :product, label_method: :work_number
    t.column :quantity
    # t.column :name, through: :building, url: true
  end

end
