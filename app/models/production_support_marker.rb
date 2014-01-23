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
# == Table: production_support_markers
#
#  aim                 :string(255)      not null
#  boolean_value       :boolean          not null
#  choice_value        :string(255)
#  created_at          :datetime         not null
#  creator_id          :integer
#  decimal_value       :decimal(19, 4)
#  derivative          :string(255)
#  geometry_value      :spatial({:srid=>
#  id                  :integer          not null, primary key
#  indicator_datatype  :string(255)      not null
#  indicator_name      :string(255)      not null
#  lock_version        :integer          default(0), not null
#  measure_value_unit  :string(255)
#  measure_value_value :decimal(19, 4)
#  multi_polygon_value :spatial({:srid=>
#  point_value         :spatial({:srid=>
#  string_value        :text
#  subject             :string(255)
#  support_id          :integer          not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#

class ProductionSupportMarker < Ekylibre::Record::Base
  include IndicatorDatumStorable
  enumerize :aim,        in: [:minimal, :maximal, :perfect], default: :perfect
  enumerize :derivative, in: Nomen::Varieties.all(:organic_matter)
  enumerize :subject,    in: [:production, :support, :derivative], default: :support, predicates: {prefix: true}
  belongs_to :support, class_name: "ProductionSupport", inverse_of: :markers
  has_one :activity, through: :production
  has_one :campaign, through: :production
  has_one :production, through: :support
  has_one :storage, through: :support
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :measure_value_value, allow_nil: true
  validates_length_of :aim, :choice_value, :derivative, :indicator_datatype, :indicator_name, :measure_value_unit, :subject, allow_nil: true, maximum: 255
  validates_inclusion_of :boolean_value, in: [true, false]
  validates_presence_of :aim, :indicator_datatype, :indicator_name, :support
  #]VALIDATORS]

  def subject_label
    if subject_production?
      return self.production.variant_name
    elsif subject_support?
      return self.support.name
    elsif subject_derivative?
      return :x_of_y.tl(x: Nomen::Varieties[self.derivative].human_name, y: Nomen::Varieties[self.production.variant_variety].human_name)
    end
  end

end
