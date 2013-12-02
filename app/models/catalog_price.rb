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
# == Table: catalog_prices
#
#  all_taxes_included :boolean          not null
#  amount             :decimal(19, 4)   not null
#  catalog_id         :integer          not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string(3)        not null
#  id                 :integer          not null, primary key
#  indicator          :string(120)      not null
#  lock_version       :integer          default(0), not null
#  reference_tax_id   :integer
#  started_at         :datetime
#  stopped_at         :datetime
#  thread             :string(20)
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer          not null
#


# CatalogPrice stores.all the prices used in sales and purchases.
class CatalogPrice < Ekylibre::Record::Base
  # attr_accessible :listing_id, :product_id, :variant_id, :pretax_amount, :amount, :tax_id, :currency, :supplier_id
  belongs_to :variant, class_name: "ProductNatureVariant"
  # belongs_to :supplier, class_name: "Entity"
  belongs_to :reference_tax, class_name: "Tax"
  belongs_to :catalog
  has_many :incoming_delivery_items, foreign_key: :price_id
  has_many :outgoing_delivery_items, foreign_key: :price_id
  has_many :purchase_items, foreign_key: :price_id
  has_many :sale_items, foreign_key: :price_id
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :thread, allow_nil: true, maximum: 20
  validates_length_of :indicator, allow_nil: true, maximum: 120
  validates_inclusion_of :all_taxes_included, in: [true, false]
  validates_presence_of :amount, :catalog, :currency, :indicator, :variant
  #]VALIDATORS]
  validates_presence_of :started_at

  #delegate :product_nature_id, :product_nature, to: :template

  scope :actives_at, lambda { |at| where("? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?)", at, at, at) }

  scope :of_variant, lambda { |variant|
    where(:variant_id => variant.id)
  }

  scope :of_usage, lambda { |usage|
    joins(:catalog).merge(Catalog.of_usage(usage))
  }

  before_validation do
    self.currency = "EUR" if self.currency.blank?
    self.indicator = :population if self.indicator.blank?
    if self.started_at.nil?
      self.started_at = Time.now
    end
    if self.name.blank?
      self.name = self.label_name
    end
    #  #self.computed_at ||= Time.now
    #  #if self.template
    #  #  self.currency ||= self.template.currency
    #   ## self.supplier ||= self.template.supplier
    #   # self.tax      ||= self.template.tax
    # # end
  end


  # validate do
  #   #if self.template
  #   #  if self.template.supplier_id != self.supplier_id
  #   #    errors.add(:supplier_id, :invalid)
  #   #  end
  #   #  if self.template.currency != self.currency
  #   #    errors.add(:currency, :invalid)
  #   #  end
  #   #end
  # end

  def label_name
    self.variant.name.to_s + ' ' + self.amount.to_s + ' ' + self.currency.to_s + ' / ' + self.variant.unit_name.to_s
  end

  def label
    tc(:label, :variant => self.variant.name, :amount => self.amount, :currency => self.currency)
  end

  def update
    current_time = Time.now
    stamper_id = self.class.stamper_class.stamper.id rescue nil
    nc = self.class.create!(self.attributes.merge(:started_at => current_time, :created_at => current_time, :updated_at => current_time, :creator_id => stamper_id, :updater_id => stamper_id).delete_if{|k,v| k.to_s == "id"})
    self.class.where(:id => self.id).update_all(:stopped_at => current_time)
    nc.ensure_by_default_uniqueness
    return nc
  end

  def destroy
    unless self.new_record?
      current_time = Time.now
      self.class.where(:id => self.id).update_all(:stopped_at => current_time)
    end
  end

  def refresh
    self.save
  end

  def compute(quantity = nil, pretax_amount = nil, amount = nil)
    if quantity
      pretax_amount = self.pretax_amount*quantity
      amount = self.amount*quantity
    elsif pretax_amount
      quantity = pretax_amount/self.pretax_amount
      amount = quantity*self.amount
    elsif amount
      quantity = amount/self.amount
      pretax_amount = quantity*self.amount
    elsif
      raise ArgumentError.new("At least one argument must be given")
    end
    return quantity.round(4), pretax_amount.round(2), amount.round(2)
  end

  # Give a price for a given product
  # Options are: :pretax_amount, :amount,
  # :template, :supplier, :at, :listing
  def price(product, options = {})
    company = Entity.of_company
    filter = {
      :variant_id => product.variant_id
    }
    # request for an existing price between dates according to filter conditions
    prices = self.actives_at(options[:at] || Time.now).where(filter)
    # request return no prices, we create a price
    if prices.count.zero?
      # prices = [self.create!({:tax_id => Tax.first.id, :pretax_amount => filter[:pretax_amount], :amount => filter[:amount]}.merge(filter))]
      # .alling private method for creating a price for given product (Product or ProductNatureVariant) with given options
      prices = new_price(product, options)
      return prices
    end
    # request return at least one price, we return the first
    if prices.count >= 1
      return prices.first
    else
      #Rails.logger.warn("#{prices.count} price found for #{options}")
      return nil
    end
  end

  private

  # Create a price with given parameters
  def new_price(product, options = {})
    computed_at = options[:at] || Time.now
    price = nil
    tax = options[:tax] || Tax.first
    # Assigned price
    pretax_amount = if options[:pretax_amount]
                      options[:pretax_amount].to_d
                    elsif options[:amount]
                      tax.pretax_amount_of(options[:amount])
                    else
                      raise StandardError.new("No amounts found, at least amount or pretax_amount must be given to create a price")
                    end
    amount = tax.amount_of(pretax_amount)
    # Amount choice
    amount = (self.all_taxes_included ? amount : pretax_amount)
    if product.is_a? Product
      price = self.create!(:variant_id => product.variant_id, :started_at => computed_at, :amount => amount.round(2), :tax_id => tax.id, :all_taxes_included => self.all_taxes_included)
    elsif product.is_a? ProductNatureVariant
      price = self.create!(:variant_id => product.id, :started_at => computed_at, :amount => amount.round(2), :tax_id => tax.id, :all_taxes_included => self.all_taxes_included)
    else
      raise ArgumentError.new("The product argument must be a Product or a ProductNatureVariant not a #{product.class.name}")
    end
    # elsif self.calculation?
    # price = // Formula

    return price
  end

end
