# coding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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

class Backend::AnimalGroupsController < BackendController
  manage_restfully

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list do |t|
    t.column :name, url: true
    t.column :description
    t.action :show, url: {:format => :pdf}, image: :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Liste des animaux d'un groupe d'animaux considéré
  list(:animals, model: :product_memberships, conditions: {group_id: 'params[:id]'.c}, order: "started_at ASC") do |t|
    t.column :member, url: true
    t.column :localize_in
    t.column :started_at
    t.column :stopped_at
  end

  # Liste des lieux du groupe d'animaux considéré
  list(:places, model: :product_localizations, conditions: {product_id: 'params[:id]'.c}, order: "started_at DESC") do |t|
    t.column :container, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

end
