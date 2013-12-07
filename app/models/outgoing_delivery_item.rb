# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: outgoing_delivery_items
#
#  created_at        :datetime         not null
#  creator_id        :integer
#  delivery_id       :integer          not null
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  population        :decimal(19, 4)   default(1.0), not null
#  product_id        :integer          not null
#  sale_item_id      :integer
#  source_product_id :integer          not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#


class OutgoingDeliveryItem < Ekylibre::Record::Base
  # attr_accessible :sale_item_id, :product_id, :price_id, :unit
  attr_readonly :sale_item_id, :product_id
  belongs_to :delivery, class_name: "OutgoingDelivery", inverse_of: :items
  # belongs_to :price, class_name: "CatalogPrice"
  belongs_to :source_product, class_name: "Product"
  belongs_to :product
  belongs_to :sale_item
  has_many :interventions, class_name: "Intervention", :as => :ressource
  # belongs_to :move, class_name: "ProductMove"
  #enumerize :unit, in: Nomen::Units.all
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_presence_of :delivery, :population, :product, :source_product
  #]VALIDATORS]

  #acts_as_stockable :quantity => '-self.quantity', :origin => :delivery
  sums :delivery, :items#, "item.product.weight" => :weight

  before_validation do
    if self.sale_item
      self.source_product_id  = self.sale_item.product_id
    end

    if self.source_product
      maximum = self.source_product.population || 0
      if self.population == maximum
        # deliver all the product source_product == product
        self.product = self.source_product
      else
        # deliver a part of the product (need to part-with) source_product <> product
        # @TODO part source_product into (product, self.quantity) and (source_product, self.source_product.population - self.quantity)
      end
    end
    true
  end

  validate(on: :create) do
    if self.source_product
      maximum = self.source_product.population || 0
      errors.add(:population, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.source_product.variant.unit_name, :product => self.source_product_name) if (self.population > maximum)
    end
    true
  end

  validate(on: :update) do
    old_self = self.old_record
    maximum = self.product.population || 0
    errors.add(:population, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.product.variant.unit_name, :product => self.product_name) if (self.population > maximum)
  end

  #def undelivered_quantity
  # self.sale_item.undelivered_quantity
  #end

  def source_product_name
    self.source_product.name
  end

end
