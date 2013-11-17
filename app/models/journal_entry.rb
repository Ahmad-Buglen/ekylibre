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
# == Table: journal_entries
#
#  absolute_credit    :decimal(19, 4)   default(0.0), not null
#  absolute_currency  :string(3)        not null
#  absolute_debit     :decimal(19, 4)   default(0.0), not null
#  balance            :decimal(19, 4)   default(0.0), not null
#  created_at         :datetime         not null
#  created_on         :date             not null
#  creator_id         :integer
#  credit             :decimal(19, 4)   default(0.0), not null
#  currency           :string(3)        not null
#  debit              :decimal(19, 4)   default(0.0), not null
#  financial_year_id  :integer
#  id                 :integer          not null, primary key
#  journal_id         :integer          not null
#  lock_version       :integer          default(0), not null
#  number             :string(255)      not null
#  printed_on         :date             not null
#  real_credit        :decimal(19, 4)   default(0.0), not null
#  real_currency      :string(3)        not null
#  real_currency_rate :decimal(19, 10)  default(0.0), not null
#  real_debit         :decimal(19, 4)   default(0.0), not null
#  resource_id        :integer
#  resource_type      :string(255)
#  state              :string(30)       not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#


class JournalEntry < Ekylibre::Record::Base
  # attr_accessible :journal_id, :number, :printed_on, :resource
  attr_readonly :journal_id, :created_on
  belongs_to :financial_year
  belongs_to :journal, inverse_of: :entries
  belongs_to :resource, :polymorphic => true
  has_many :affairs, dependent: :nullify
  has_many :asset_depreciations, dependent: :nullify
  has_many :useful_items, -> { where("balance != ?", 0.0) }, foreign_key: :entry_id, class_name: "JournalEntryItem"
  has_many :items, foreign_key: :entry_id, dependent: :delete_all, class_name: "JournalEntryItem", inverse_of: :entry
  has_many :outgoing_payments, dependent: :nullify
  has_many :incoming_payments, dependent: :nullify
  has_many :purchases, dependent: :nullify
  has_many :sales, dependent: :nullify
  has_one :financial_year_as_last, foreign_key: :last_journal_entry_id, class_name: "FinancialYear", dependent: :nullify
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :absolute_credit, :absolute_debit, :balance, :credit, :debit, :real_credit, :real_currency_rate, :real_debit, allow_nil: true
  validates_length_of :absolute_currency, :currency, :real_currency, allow_nil: true, maximum: 3
  validates_length_of :state, allow_nil: true, maximum: 30
  validates_length_of :number, :resource_type, allow_nil: true, maximum: 255
  validates_presence_of :absolute_credit, :absolute_currency, :absolute_debit, :balance, :created_on, :credit, :currency, :debit, :journal, :number, :printed_on, :real_credit, :real_currency, :real_currency_rate, :real_debit, :state
  #]VALIDATORS]
  validates_presence_of :real_currency
  validates_format_of :number, :with => /\A[\dA-Z]+\z/
  validates_numericality_of :real_currency_rate, :greater_than => 0

  accepts_nested_attributes_for :items

  state_machine :state, :initial => :draft do
    state :draft
    state :confirmed
    state :closed
    event :confirm do
      transition :draft => :confirmed, :if => :balanced?
    end
    event :close do
      transition :confirmed => :closed, :if => :balanced?
    end
#     event :reopen do
#       transition :closed => :confirmed
#     end
  end

  # Build an SQL condition based on options which should contains acceptable states
  def self.state_condition(states={}, table_name=nil)
    table = table_name || self.table_name
    states = {} unless states.is_a? Hash
    if states.empty?
      return JournalEntry.connection.quoted_false
    else
      return "#{table}.state IN (#{states.collect{|s, v| JournalEntry.connection.quote(s)}.join(',')})"
    end
  end

  # Build an SQL condition based on options which should contains acceptable states
  def self.journal_condition(journals={}, table_name=nil)
    table = table_name || self.table_name
    journals = {} unless journals.is_a? Hash
    if journals.empty?
      return JournalEntry.connection.quoted_false
    else
      return "#{table}.journal_id IN (#{journals.collect{|s, v| JournalEntry.connection.quote(s.to_i)}.join(',')})"
    end
  end

  # Build a condition for filter journal entries on period
  def self.period_condition(period, started_on, stopped_on, table_name=nil)
    table = table_name || self.table_name
    if period.to_s == 'all'
      return self.connection.quoted_true
    else
      conditions = []
      started_on, stopped_on = period.to_s.split('_')[0..1] unless period == 'interval'
      if (started_on = started_on.to_date rescue nil)
        conditions << "#{table}.printed_on >= #{self.connection.quote(started_on)}"
      end
      if (stopped_on = stopped_on.to_date rescue nil)
        conditions << "#{table}.printed_on <= #{self.connection.quote(stopped_on)}"
      end
      return self.connection.quoted_false if conditions.empty?
      return '('+conditions.join(' AND ')+')'
    end
  end

  # Returns states names
  def self.states
    self.state_machine.states.collect{|x| x.name}
  end

  #
  before_validation do
    if self.journal
      self.real_currency = self.journal.currency
    end
    self.financial_year = FinancialYear.at(self.printed_on)
    self.currency = self.financial_year.currency
    if self.real_currency and self.financial_year
      if self.real_currency == self.financial_year.currency
        self.real_currency_rate = 1
      else
        # TODO: Find a better way to manage currency rates!
        # raise self.financial_year.inspect if I18n.currencies(self.financial_year.currency).nil?
        self.real_currency_rate = I18n.currency_rate(self.real_currency, self.currency)
      end
    else
      self.real_currency_rate = 1
    end
    self.real_debit  = self.items.sum(:real_debit)
    self.real_credit = self.items.sum(:real_credit)
    self.debit  = self.items.sum(:debit)
    self.credit = self.items.sum(:credit)
    self.balance = self.debit - self.credit
    self.absolute_currency ||= self.currency
    if self.absolute_currency == self.currency
      self.absolute_debit = self.real_debit
      self.absolute_credit = self.real_credit
    end
    self.created_on = Date.today
    if self.journal and not self.number
      self.number ||= self.journal.next_number
    end
  end

  validate(:on => :update) do
    old = self.class.find(self.id)
    errors.add(:number, :entry_has_been_already_validated) if old.closed?
  end

  #
  validate do
    # TODO: Validates number has journal's code as prefix
    return unless self.created_on
    if self.journal
      errors.add(:printed_on, :closed_journal, :journal => self.journal.name, :closed_on => ::I18n.localize(self.journal.closed_on)) if self.printed_on <= self.journal.closed_on
    end
    unless self.financial_year
      errors.add(:printed_on, :out_of_existing_financial_year)
    end
  end

  after_save do
    JournalEntryItem.where(:entry_id => self.id).update_all(:state => self.state, :journal_id => self.journal_id, :financial_year_id => self.financial_year_id, :printed_on => self.printed_on, :entry_number => self.number, :real_currency => self.real_currency, :real_currency_rate => self.real_currency_rate)
  end

  protect(:on => :destroy) do
    self.printed_on > self.journal.closed_on and not self.closed?
  end

  protect(:on => :update) do
    self.printed_on > self.journal.closed_on and not self.closed?
  end

  def self.state_label(state)
    tc('states.'+state.to_s)
  end

  # Prints human name of current state
  def state_label
    self.class.state_label(self.state)
  end

  #determines if the entry is balanced or not.
  def balanced?
    self.balance.zero? # and self.items.count > 0
  end

  # this method computes the debit and the credit of the entry.
  def refresh
    self.reload
    self.save!
  end

  # Add a entry which cancel the entry
  # Create counter-entry_items
  def cancel
    reconcilable_accounts = []
    entry = self.class.new(:journal => self.journal, :resource => self.resource, :real_currency => self.real_currency, :real_currency_rate => self.real_currency_rate, :printed_on => self.printed_on)
    ActiveRecord::Base.transaction do
      entry.save!
      for item in self.useful_items
        entry.send(:add!, tc(:entry_cancel, :number => self.number, :name => item.name), item.account, (item.debit-item.credit).abs, :credit => (item.debit>0))
        reconcilable_accounts << item.account if item.account.reconcilable? and not reconcilable_accounts.include?(item.account)
      end
    end
    # Mark accounts
    for account in reconcilable_accounts
      account.mark_entries(self, entry)
    end
    return entry
  end

  def save_with_items(entry_items)
    ActiveRecord::Base.transaction do
      saved = self.save
      self.items.clear
      entry_items.each_index do |index|
        entry_items[index] = self.items.build(entry_items[index])
        if saved
          saved = false unless entry_items[index].save
        end
      end
      self.reload if saved
      if saved and (not self.balanced? or self.items.size.zero?)
        self.errors.add(:debit, :unbalanced)
        saved = false
      end
      if saved
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    return false
  end



#   #this method tests if.all the entry_items matching to the entry does not edited in draft mode.
#   def normalized
#     return (not self.items.exists?(:draft => true))
#   end

  # Adds an entry_item with the minimum informations. It computes debit and credit with the "amount".
  # If the amount is negative, the amount is put in the other column (debit or credit). Example:
  #   entry.add_debit("blabla", account, -65) # will put +65 in +credit+ column
  def add_debit(name, account, amount, options={})
    add!(name, account, amount, options)
  end

  #
  def add_credit(name, account, amount, options={})
    add!(name, account, amount, options.merge({:credit => true}))
  end


  private

  #
  def add!(name, account, amount, options={})
    # return if amount == 0
    if name.size > 255
      omission = (options.delete(:omission)||"...").to_s
      name = name[0..254-omission.size]+omission
    end
    credit = options.delete(:credit) ? true : false
    credit = (not credit) if amount < 0
    attributes = options.merge(:name => name)
    attributes[:account_id] = account.is_a?(Integer) ? account : account.id
    # attributes[:real_currency] = self.journal.currency
    if credit
      attributes[:real_credit] = amount.abs
      attributes[:real_debit]  = 0.0
    else
      attributes[:real_credit] = 0.0
      attributes[:real_debit]  = amount.abs
    end
    e = self.items.create!(attributes)
    return e
  end


end
