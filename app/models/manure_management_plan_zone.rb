# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: manure_management_plan_zones
#
#  absorbed_nitrogen_at_opening                    :decimal(19, 4)
#  computation_method                              :string(255)      not null
#  created_at                                      :datetime         not null
#  creator_id                                      :integer
#  humus_mineralization                            :decimal(19, 4)
#  id                                              :integer          not null, primary key
#  intermediate_cultivation_residue_mineralization :decimal(19, 4)
#  irrigation_water_nitrogen                       :decimal(19, 4)
#  lock_version                                    :integer          default(0), not null
#  meadow_humus_mineralization                     :decimal(19, 4)
#  membership_id                                   :integer          not null
#  mineral_nitrogen_at_opening                     :decimal(19, 4)
#  nitrogen_at_closing                             :decimal(19, 4)
#  nitrogen_input                                  :decimal(19, 4)
#  nitrogen_need                                   :decimal(19, 4)
#  organic_fertilizer_mineral_fraction             :decimal(19, 4)
#  plan_id                                         :integer          not null
#  previous_cultivation_residue_mineralization     :decimal(19, 4)
#  soil_production                                 :decimal(19, 4)
#  support_id                                      :integer          not null
#  updated_at                                      :datetime         not null
#  updater_id                                      :integer
#
class ManureManagementPlanZone < Ekylibre::Record::Base
  belongs_to :plan, class_name: "ManureManagementPlan", inverse_of: :zones
  belongs_to :support, class_name: "ProductionSupport"
  belongs_to :membership, class_name: "CultivableZoneMembership"
  has_one :activity, through: :production
  has_one :campaign, through: :plan
  has_one :cultivable_zone, through: :membership, source: :group
  has_one :land_parcel, through: :membership, source: :member
  has_one :production, through: :support
  enumerize :computation_method, in: Nomen::ManureManagementPlanComputationMethods.all
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :absorbed_nitrogen_at_opening, :humus_mineralization, :intermediate_cultivation_residue_mineralization, :irrigation_water_nitrogen, :meadow_humus_mineralization, :mineral_nitrogen_at_opening, :nitrogen_at_closing, :nitrogen_input, :nitrogen_need, :organic_fertilizer_mineral_fraction, :previous_cultivation_residue_mineralization, :soil_production, allow_nil: true
  validates_length_of :computation_method, allow_nil: true, maximum: 255
  validates_presence_of :computation_method, :membership, :plan, :support
  #]VALIDATORS]

  delegate :locked?, to: :plan

  protect do
    self.locked?
  end
end
