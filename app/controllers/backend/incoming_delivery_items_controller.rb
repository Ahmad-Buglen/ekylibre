# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2013 Brice Texier
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

class Backend::IncomingDeliveryItemsController < BackendController

  def new
    if request.xhr? and params[:variant_id]
      unless @incoming_delivery = IncomingDelivery.find_by(id: params[:incoming_delivery_id])
        @incoming_delivery = IncomingDelivery.new
      end
      return unless variant = find_and_check(:product_nature_variant, params[:variant_id])
      params[:external] ||= false
      @incoming_delivery.items.build(product_nature_variant_id: variant.id) # (:id => rand(1_000_000_000))
      # id = rand(1_000_000_000)
      # @incoming_delivery_items = @incoming_delivery.items.build(:id => id)
      # @incoming_delivery_item = @incoming_delivery.items.build(:id => id)
      render :partial => "nested_form"
    else
      head :forbidden
    end
  end


end
