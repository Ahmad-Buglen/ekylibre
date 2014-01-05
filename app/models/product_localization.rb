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
# == Table: product_localizations
#
#  arrival_cause   :string(255)
#  container_id    :integer
#  created_at      :datetime         not null
#  creator_id      :integer
#  departure_cause :string(255)
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  nature          :string(255)      not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string(255)
#  product_id      :integer          not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#

class ProductLocalization < Ekylibre::Record::Base
  include Taskable, TimeLineable
  belongs_to :container, class_name: "Product"
  belongs_to :product
  enumerize :nature, in: [:transfer, :interior, :exterior], predicates: true
  enumerize :arrival_cause,   in: [:other, :birth, :housing, :purchase], default: :other, predicates: {prefix: true}
  enumerize :departure_cause, in: [:other, :death, :consumption, :sale], default: :other, predicates: {prefix: true}
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :arrival_cause, :departure_cause, :nature, :originator_type, allow_nil: true, maximum: 255
  validates_presence_of :nature, :product
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values
  validates_presence_of :container, :if => :interior?
  validates_presence_of :arrival_cause

  before_save do
    self.container = nil unless self.interior?
    return true
  end

  after_save do
    # # Detach from carrier if exists but only if it has linkage points ?
    # self.product.carrier_linkages.at(self.started_at).find_each do |linkage|
    #   self.product_linkages.create!(carrier_id: linkage.carrier_id, point: linkage.point, started_at: self.started_at, nature: :available)
    # end
    # Move carried products
    self.product.linkages.at(self.started_at).find_each do |linkage|
      if linkage.occupied? and carried = linkage.carried
        localization = carried.localizations.at(self.started_at).first
        if localization.nil? or (localization.nature != self.nature or localization.container_id != self.container_id)
          self.product_localizations.create!(product: linkage.carried, operation: self.operation, nature: self.nature, container: self.container, started_at: self.started_at, arrival_cause: self.arrival_cause, departure_cause: self.departure_cause)
        end
      end
    end
    return true
  end

  protect do
    self.intervention.present?
  end

  private

  # Returns all siblings in the chronological line
  def siblings
    (self.product ? self.product.localizations : self.class.none)
  end

end
