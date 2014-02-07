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
# == Table: product_nature_variant_readings
#
#  absolute_measure_value_unit  :string(255)
#  absolute_measure_value_value :decimal(19, 4)
#  boolean_value                :boolean          not null
#  choice_value                 :string(255)
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  decimal_value                :decimal(19, 4)
#  geometry_value               :spatial({:srid=>
#  id                           :integer          not null, primary key
#  indicator_datatype           :string(255)      not null
#  indicator_name               :string(255)      not null
#  integer_value                :integer
#  lock_version                 :integer          default(0), not null
#  measure_value_unit           :string(255)
#  measure_value_value          :decimal(19, 4)
#  multi_polygon_value          :spatial({:srid=>
#  point_value                  :spatial({:srid=>
#  string_value                 :text
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  variant_id                   :integer          not null
#


class ProductNatureVariantReading < Ekylibre::Record::Base
  include ReadingStorable
  belongs_to :variant, class_name: "ProductNatureVariant", inverse_of: :readings

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :integer_value, allow_nil: true, only_integer: true
  validates_numericality_of :absolute_measure_value_value, :decimal_value, :measure_value_value, allow_nil: true
  validates_length_of :absolute_measure_value_unit, :choice_value, :indicator_datatype, :indicator_name, :measure_value_unit, allow_nil: true, maximum: 255
  validates_inclusion_of :boolean_value, in: [true, false]
  validates_presence_of :indicator_datatype, :indicator_name, :variant
  #]VALIDATORS]

  validate do
    if self.variant
      unless self.variant.frozen_indicators.include?(self.indicator)
        errors.add(:indicator, :invalid)
      end
    end
  end

end
