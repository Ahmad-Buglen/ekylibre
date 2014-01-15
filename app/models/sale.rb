# -*- coding: utf-8 -*-
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
# == Table: sales
#
#  accounted_at        :datetime
#  address_id          :integer
#  affair_id           :integer
#  amount              :decimal(19, 4)   default(0.0), not null
#  annotation          :text
#  client_id           :integer          not null
#  conclusion          :text
#  confirmed_on        :date
#  created_at          :datetime         not null
#  created_on          :date             not null
#  creator_id          :integer
#  credit              :boolean          not null
#  currency            :string(3)        not null
#  delivery_address_id :integer
#  description         :text
#  downpayment_amount  :decimal(19, 4)   default(0.0), not null
#  expiration_delay    :string(255)
#  expired_on          :date
#  function_title      :string(255)
#  has_downpayment     :boolean          not null
#  id                  :integer          not null, primary key
#  initial_number      :string(60)
#  introduction        :text
#  invoice_address_id  :integer
#  invoiced_on         :date
#  journal_entry_id    :integer
#  letter_format       :boolean          default(TRUE), not null
#  lock_version        :integer          default(0), not null
#  nature_id           :integer
#  number              :string(60)       not null
#  origin_id           :integer
#  payment_delay       :string(255)      not null
#  payment_on          :date
#  pretax_amount       :decimal(19, 4)   default(0.0), not null
#  reference_number    :string(255)
#  responsible_id      :integer
#  state               :string(60)       not null
#  subject             :string(255)
#  transporter_id      :integer
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class Sale < Ekylibre::Record::Base
  attr_readonly :created_on, :currency
  belongs_to :client, class_name: "Entity"
  belongs_to :payer, class_name: "Entity", foreign_key: :client_id
  belongs_to :address, class_name: "EntityAddress"
  belongs_to :delivery_address, class_name: "EntityAddress"
  belongs_to :invoice_address, class_name: "EntityAddress"
  belongs_to :journal_entry
  belongs_to :nature, class_name: "SaleNature"
  belongs_to :origin, class_name: "Sale"
  belongs_to :responsible, class_name: "Person"
  belongs_to :transporter, class_name: "Entity"
  has_many :credits, class_name: "Sale", foreign_key: :origin_id
  has_many :deliveries, class_name: "OutgoingDelivery", dependent: :destroy, inverse_of: :sale
  has_many :documents, :as => :owner
  has_many :items, -> { order("position, id") }, class_name: "SaleItem", foreign_key: :sale_id, dependent: :destroy, inverse_of: :sale
  has_many :journal_entries, :as => :resource
  has_many :subscriptions, class_name: "Subscription"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :downpayment_amount, :pretax_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :initial_number, :number, :state, allow_nil: true, maximum: 60
  validates_length_of :expiration_delay, :function_title, :payment_delay, :reference_number, :subject, allow_nil: true, maximum: 255
  validates_inclusion_of :credit, :has_downpayment, :letter_format, in: [true, false]
  validates_presence_of :amount, :client, :created_on, :currency, :downpayment_amount, :number, :payer, :payment_delay, :pretax_amount, :state
  #]VALIDATORS]
  validates_presence_of :client, :currency, :nature
  validates_presence_of :invoiced_on, :if => :invoice?
  validates_delay_format_of :payment_delay, :expiration_delay

  acts_as_numbered :number, :readonly => false
  acts_as_affairable :client, debit: :credit
  accepts_nested_attributes_for :items # , :reject_if => :all_blank, :allow_destroy => true
  after_create {|r| r.client.add_event(:sale, r.updater_id)}

  delegate :closed, to: :affair, prefix: true

  scope :invoiced_between, lambda { |started_on, stopped_on|
    where("invoiced_on BETWEEN ? AND ?", started_on, stopped_on)
  }

  state_machine :state, :initial => :draft do
    state :draft
    state :estimate
    state :refused
    state :order
    state :invoice
    state :aborted

    event :propose do
      transition :draft => :estimate, :if => :has_content?
    end
    event :correct do
      transition :estimate => :draft
      transition :refused => :draft
      # @TODO define a method to replace paid_amount in Affair
      transition :order => :draft#, :if => Proc.new{|so| so.paid_amount <= 0}
    end
    event :refuse do
      transition :estimate => :refused, :if => :has_content?
    end
    event :confirm do
      transition :estimate => :order, :if => :has_content?
    end
    event :invoice do
      transition :order => :invoice, :if => :has_content?
      transition :estimate => :invoice, :if => :has_content_not_deliverable?
    end
    event :abort do
      # transition [:draft, :estimate] => :aborted # , :order
      transition :draft => :aborted # , :order
    end
  end

  before_validation(on: :create) do
    self.state ||= self.class.state_machine.initial_state(self)
    self.currency = self.nature.currency if self.nature
    self.created_on = Date.today
  end

  before_validation do
    if self.address.nil? and self.client
      dc = self.client.default_mail_address
      self.address_id = dc.id if dc
    end
    self.delivery_address_id ||= self.address_id
    self.invoice_address_id  ||= self.delivery_address_id
    self.created_on ||= Date.today
    self.nature ||= SaleNature.by_default if self.nature.nil?
    if self.nature
      self.expiration_delay ||= self.nature.expiration_delay
      self.expired_on ||= Delay.new(self.expiration_delay).compute(self.created_on)
      self.payment_delay ||= self.nature.payment_delay
      self.has_downpayment = self.nature.downpayment if self.has_downpayment.nil?
      self.downpayment_amount ||= (self.amount * self.nature.downpayment_percentage * 0.01) if self.amount >= self.nature.downpayment_minimum
      self.currency ||= self.nature.currency
    end
    true
  end

  before_update do
    old = self.class.find(self.id)
    if old.invoice?
      for attr in self.class.columns_definition.keys
        self.send(attr + "=", old.send(attr))
      end
    end
  end

  validate do
    for mail_address in [:address, :delivery_address, :invoice_address]
      if self.send(mail_address)
        unless self.send(mail_address).mail?
          errors.add(mail_address, :must_be_a_mail_address)
        end
      end
    end
  end

  # This method bookkeeps the sale depending on its state
  bookkeep do |b|
    b.journal_entry(self.nature.journal, :printed_on => self.invoiced_on, :if => (self.nature.with_accounting? and self.invoice?)) do |entry|
      label = tc(:bookkeep, :resource => self.state_label, :number => self.number, :client => self.client.full_name, :products => (self.description.blank? ? self.items.collect{|x| x.label}.to_sentence : self.description), :sale => self.initial_number)
      entry.add_debit(label, self.client.account(:client).id, self.amount) unless self.amount.zero?
      for item in self.items
        entry.add_credit(label, (item.account||item.variant.sales_account).id, item.pretax_amount) unless item.pretax_amount.zero?
        entry.add_credit(label, item.tax.collect_account_id, item.taxes_amount) unless item.taxes_amount.zero?
      end
    end
  end


  # Gives the date to use for affair bookkeeping
  def dealt_on
    return (self.invoice? ? self.invoiced_on : self.created_on)
  end

  # Gives the amount to use for affair bookkeeping
  def deal_amount
    return (self.credit? ? -self.amount : self.amount)
  end

  # Globalizes taxes into an array of hash
  def deal_taxes(debit = false)
    taxes = {}
    coeff = (self.credit? ? -1 : 1)
    coeff *= (self.send("deal_#{debit ? :debit : :credit}?") ? 1 : -1)
    for item in self.items
      tax_id = item.tax ? item.tax_id : :none
      taxes[tax_id] ||= {amount: 0.0, tax: item.tax}
      taxes[tax_id][:amount] += coeff * item.amount
    end
    return taxes.values
  end

  def supplier
    Entity.of_company
  end

  def client_number
    self.client.number
  end

  def nature=(value)
    super(value)
    self.currency = self.nature.currency if self.nature
  end

  # Save a new time
  def refresh
    self.save
  end

  # Test if there is some items in the sale.
  def has_content?
    self.items.count > 0
  end

  def has_content_not_deliverable?
    return false unless self.has_content?
    deliverable = false
    for item in self.items
      deliverable = true if item.variant.deliverable?
    end
    return !deliverable
  end

  # Returns if the sale has been validated and so if it can be
  # considered as sold.
  def sold?
    return (self.order? or self.invoice?)
  end


  # Remove.all bad dependencies and return at draft state with no deliveries
  def correct(*args)
    return false unless self.can_correct?
    self.deliveries.clear
    return super
  end

  # Confirm the sale order. This permits to define deliveries and assert validity of sale
  def confirm(validated_on=Date.today, *args)
    return false unless self.can_confirm?
    self.reload.update_attributes!(:confirmed_on => validated_on||Date.today)
    return super
  end


  # # Create the last delivery with undelivered products if necessary.
  # # The sale order is confirmed if it hasn't be done.
  # def deliver
  #   # TODO A sale cannot be delivered anymore...
  #   ActiveSupport::Deprecation.warn "A sale cannot be delivered. Use deliveries to deliver product instead."
  #   return false
  #   return false unless self.order?
  #   items = []
  #   for item in self.items.not_reduction
  #     quantity = item.undelivered_quantity
  #     if quantity > 0 and item.deliverable?
  #       items << {:sale_item_id => item.id, :quantity => quantity}
  #     end
  #   end
  #   if items.count > 0
  #     delivery = self.deliveries.create!(:pretax_amount => 0, :amount => 0, :planned_on => Date.today, :moved_on => Date.today, :address_id => self.delivery_address_id)
  #     for item in items
  #       delivery.items.create! item
  #     end
  #     self.refresh
  #   end
  #   self
  # end


  # Invoices.all the products creating the delivery if necessary.
  # Changes number with an invoice number saving exiting number in +initial_number+.
  def invoice(*args)
    return false unless self.can_invoice?
    self.confirm
    ActiveRecord::Base.transaction do
      # Set values for invoice
      self.invoiced_on = Date.today
      self.payment_on ||= Delay.new(self.payment_delay).compute(self.invoiced_on)
      self.initial_number = self.number
      if sequence = Sequence.of(:sales_invoices)
        self.number = sequence.next_value
      end
      self.save
      self.client.add_event(:sales_invoice, self.updater_id)
      return super
    end
    return false
  end

  # Delivers.all undelivered products and sales invoice the order after. This operation cleans the order.
  def deliver_and_invoice
    self.deliver.invoice
  end

  # Duplicates a +sale+ in 'E' mode with its items and its active subscriptions
  def duplicate(attributes={})
    fields = [:client_id, :nature_id, :currency, :letter_format, :annotation, :subject, :function_title, :introduction, :conclusion, :description]
    hash = {}
    fields.each{|c| hash[c] = self.send(c)}
    copy = self.class.build(attributes.merge(hash))
    copy.save!
    if copy.save
      # Items
      items = {}
      for item in self.items.where("quantity > 0")
        l = copy.items.create! :sale_id => copy.id, :product_id => item.product_id, :quantity => item.quantity, :building_id => item.building_id
        items[item.id] = l.id
      end
      # Subscriptions
      for sub in self.subscriptions.where("NOT suspended")
        copy.subscriptions.create!(:sale_id => copy.id, :entity_id => sub.entity_id, :address_id => sub.address_id, :quantity => sub.quantity, :nature_id => sub.nature_id, :product_id => sub.product_id, :sale_item_id => items[sub.sale_item_id])
      end
    else
      raise Exception.new(copy.errors.inspect)
    end
    copy
  end



  # # Produces some amounts about the sale order.
  # # Some options can be used:
  # # - +:multi_sales_invoices+ adds the uninvoiced amount and invoiced amount
  # # - +:with_balance+ adds the balance of the client of the sale order
  # def stats(options={})
  #   array = []
  #   array << [:client_balance, self.client.balance] if options[:with_balance]
  #   array << [:amount, self.amount]
  #   array << [:paid_amount, self.paid_amount]
  #   array << [:unpaid_amount, self.unpaid_amount]
  #   array
  # end


  def self.state_label(state)
    tc('states.'+state.to_s)
  end

  # Prints human name of current state
  def state_label
    self.class.state_label(self.state)
  end

  # # Computes an amount (with or without taxes) of the undelivered products
  # # - +column+ can be +:amount+ or +:pretax_amount+
  # def undelivered(column)
  #   return (self.items.sum(column) - self.deliveries.sum(column)).round(2)
  # end


  # Returns true if there is some products to deliver
  def deliverable?
    # not self.undelivered(:quantity).zero? and (self.invoice? or self.order?)
    # !self.undelivered_items.count.zero? and (self.invoice? or self.order?)
    true
  end

  # # Calculate unpaid amount
  # def unpaid_amount
  #   self.amount - self.paid_amount
  # end

  # Label of the sales order depending on the state and the number
  def name
    tc('label.' + self.state, :number => self.number)
  end
  alias :label :name

  # Alias for letter_format? method
  def letter?
    self.letter_format?
  end

  # def tags
  #   if self.order? or self.invoice? and !self.credit? and !self.amount.zero?
  #     if self.paid_amount.zero?
  #       return "critic "+self.state
  #     elsif self.paid_amount != self.amount
  #       return "warning "+self.state
  #     else
  #       return self.state
  #     end
  #   elsif self.credit?
  #     return "disabled "+self.state
  #   end
  #   return self.state
  # end

  def mail_address
    return (self.address || self.client.default_mail_address).mail_coordinate
  end

  def number_label
    tc("number_label."+(self.estimate? ? 'proposal' : 'command'), :number => self.number)
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end

  def usable_payments
    self.client.incoming_payments.where("COALESCE(used_amount, 0)<COALESCE(amount, 0)").joins(:mode => :cash).where(currency: self.currency).order("to_bank_on")
  end

  # Build general sales condition for the sale order
  def sales_conditions
    c = []
    c << tc('sales_conditions.downpayment', :percentage => self.nature.downpayment_percentage, :amount => (self.nature.downpayment_percentage * 0.01 * self.amount).round(2)) if self.amount > self.nature.downpayment_minimum
    c << tc('sales_conditions.validity', :expiration => ::I18n.localize(self.expired_on, :format => :legal))
    c += self.nature.sales_conditions.to_s.split(/\s*\n\s*/)
    c += self.responsible.department.sales_conditions.to_s.split(/\s*\n\s*/) if self.responsible and self.responsible.department
    c
  end

  def unpaid_days
    (Date.today - self.invoiced_on) if self.invoice?
  end

  def products
    p = []
    for item in self.items
      p << item.product.name
    end
    ps = p.join(", ")
  end

  # Returns true if sale is cancelable as an invoice
  def cancelable?
    not self.credit? and self.invoice? and self.amount + self.credits.sum(:amount) > 0
  end

  # Create a credit for the selected invoice? guarding the reference
  def cancel(items = {}, options = {})
    items = items.delete_if{|k,v| v.zero?}
    return false if !self.cancelable? or items.size.zero?
    credit = self.class.new(:origin_id => self.id, :client_id => self.client_id, :credit => true, :responsible => options[:responsible]||self.responsible, :nature_id => self.nature_id)
    ActiveRecord::Base.transaction do
      if saved = credit.save
        for item in self.items.where(:id => items.keys)
          quantity = -items[item.id.to_s].abs
          credit_item = credit.items.create(:quantity => quantity, :origin_id => item.id, :product_id => item.product_id, :price_id => item.price_id, :reduction_percentage => item.reduction_percentage)
          unless credit_item.save
            saved = false
            credit.errors.add_from_record(credit_item)
          end
        end
      else
        raise credit.errors.full_messages.inspect
      end
      if saved
        credit.reload
        credit.propose!
        # TODO: Manage returning deliveries because of the partial/total cancel
        credit.confirm!
        credit.invoice!
        self.reload.save
      else
        raise ActiveRecord::Rollback
      end
    end
    return credit
  end

  def status
    if self.accounted_at == nil
      return (self.invoice ? :caution : :stop)
    elsif self.accounted_at
      return :go
    end
  end

end


