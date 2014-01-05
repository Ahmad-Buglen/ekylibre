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

class Backend::EntityAddressesController < BackendController
  manage_restfully :mail_country => "Entity.find(params[:entity_id]).country rescue Preference[:country]".c, :t3e => {entity: "@entity_address.entity.full_name".c}, except: [:index, :show]
  unroll label: :coordinate

  def show
    if @entity_address = EntityAddress.find_by(id: params[:id])
      redirect_to backend_entity_url(@entity_address.entity_id)
    else
      redirect_to backend_root_url
    end
  end

end
