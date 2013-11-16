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

class Backend::ProductsController < BackendController
  manage_restfully t3e: {nature_name: :nature_name}, subclass_inheritance: true

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  before_action :check_variant_availability, only: :new

  unroll

  list do |t|
    # t.column :active
    t.column :number, url: true
    t.column :name, url: true
    t.column :variant, url: true
    t.column :variety
    t.column :localize_in
    t.column :description
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # def index
  #   @product = Product.all
  #   respond_with @product, :include => [:father, :mother]
  # end

  # content product list of the consider product
  list(:contained_products, :model => :product_localizations, :conditions => {container_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :product, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # localization of the consider product
  list(:places, :model => :product_localizations, :conditions => {product_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :container, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # groups of the consider product
  list(:groups, :model => :product_memberships, :conditions => {member_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :group, url: true
    t.column :started_at
    t.column :stopped_at
  end

  # members of the consider product
  list(:members, :model => :product_memberships, :conditions => {group_id: 'params[:id]'.c}, :order => "started_at ASC") do |t|
    t.column :member, url: true
    t.column :started_at
    t.column :stopped_at
  end

  # indicators of the consider product
  list(:indicators, :model => :product_indicator_data, :conditions => {product_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :indicator
    t.column :measured_at
    t.column :value
  end

  # incidents of the consider product
  list(:incidents, :conditions => {target_id: 'params[:id]'.c}, :order => "observed_at DESC") do |t|
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    t.column :gravity
    t.column :priority
    t.column :state
  end

  # incidents of the consider product
  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :intervention, url: true
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
  end

  # def show
  #   return unless @product = find_and_check
  #   if @product.type != "Product"
  #     redirect_to controller: @product.type.tableize, action: :show, id: @product.id
  #     return
  #   end
  #   t3e @product, :nature_name => @product.nature_name
  #   respond_with(@product, :include => [:father, :mother, :nature, {:memberships => {:include => :group},:indicator_data => {:include => :indicator}, :product_localizations => {:include => :container}}])
  # end

  def check_variant_availability()
    unless ProductNatureVariant.of_variety(controller_name.to_s.underscore.singularize).any?
      redirect_to new_backend_product_nature_url
      return false
    end
  end


end
