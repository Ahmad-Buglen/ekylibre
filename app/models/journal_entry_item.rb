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
# == Table: journal_entry_items
#
#  absolute_credit           :decimal(19, 4)   default(0.0), not null
#  absolute_currency         :string(3)        not null
#  absolute_debit            :decimal(19, 4)   default(0.0), not null
#  account_id                :integer          not null
#  balance                   :decimal(19, 4)   default(0.0), not null
#  bank_statement_id         :integer
#  created_at                :datetime         not null
#  creator_id                :integer
#  credit                    :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_credit :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_debit  :decimal(19, 4)   default(0.0), not null
#  currency                  :string(3)        not null
#  debit                     :decimal(19, 4)   default(0.0), not null
#  description               :text
#  entry_id                  :integer          not null
#  entry_number              :string(255)      not null
#  financial_year_id         :integer          not null
#  id                        :integer          not null, primary key
#  journal_id                :integer          not null
#  letter                    :string(8)
#  lock_version              :integer          default(0), not null
#  name                      :string(255)      not null
#  position                  :integer
#  printed_on                :date             not null
#  real_credit               :decimal(19, 4)   default(0.0), not null
#  real_currency             :string(3)        not null
#  real_currency_rate        :decimal(19, 10)  default(0.0), not null
#  real_debit                :decimal(19, 4)   default(0.0), not null
#  state                     :string(32)       not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#


class JournalEntryItem < Ekylibre::Record::Base
  # attr_accessible :entry_id, :journal_id, :real_credit, :real_debit, :account_id, :name
  attr_readonly :entry_id, :journal_id, :state
  belongs_to :account
  belongs_to :journal, :inverse_of => :entry_items
  belongs_to :entry, :class_name => "JournalEntry", :inverse_of => :items
  belongs_to :bank_statement
  has_many :repartitions, :class_name => "AnalyticRepartition", :foreign_key => :journal_entry_item_id
  # delegate :real_currency, :to => :entry

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :absolute_credit, :absolute_debit, :balance, :credit, :cumulated_absolute_credit, :cumulated_absolute_debit, :debit, :real_credit, :real_currency_rate, :real_debit, :allow_nil => true
  validates_length_of :absolute_currency, :currency, :real_currency, :allow_nil => true, :maximum => 3
  validates_length_of :letter, :allow_nil => true, :maximum => 8
  validates_length_of :state, :allow_nil => true, :maximum => 32
  validates_length_of :entry_number, :name, :allow_nil => true, :maximum => 255
  validates_presence_of :absolute_credit, :absolute_currency, :absolute_debit, :account, :balance, :credit, :cumulated_absolute_credit, :cumulated_absolute_debit, :currency, :debit, :entry, :entry_number, :journal, :name, :printed_on, :real_credit, :real_currency, :real_currency_rate, :real_debit, :state
  #]VALIDATORS]
  validates_numericality_of :debit, :credit, :real_debit, :real_credit, :greater_than_or_equal_to => 0
  validates_presence_of :account
  # validates_uniqueness_of :letter, :scope => :account_id, :if => Proc.new{|x| !x.letter.blank?}

  acts_as_list :scope => :entry
  after_create  :update_entry
  after_destroy :update_entry
  after_destroy :unmark
  after_update  :update_entry

  scope :between, lambda { |started_on, stopped_on|
    joins("JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)").where("printed_on BETWEEN ? AND ? ", started_on, stopped_on).order("printed_on, journal_entries.id, journal_entry_items.id")
  }

  state_machine :state, :initial => :draft do
    state :draft
    state :confirmed
    state :closed
  end

  #
  before_validation do
    self.name = self.name.to_s[0..254]
    # computes the values depending on currency rate
    # for debit and credit.
    self.real_debit  ||= 0
    self.real_credit ||= 0
    if self.entry
      self.entry_number = self.entry.number
      for replicated in [:financial_year_id, :printed_on, :journal_id, :state, :currency, :real_currency, :real_currency_rate]
        self.send("#{replicated}=", self.entry.send(replicated))
      end
      unless self.closed?
        self.debit  = self.entry.real_currency.to_currency.round(self.real_debit * self.real_currency_rate)
        self.credit = self.entry.real_currency.to_currency.round(self.real_credit * self.real_currency_rate)
      end
    end

    self.absolute_currency ||= self.currency
    if self.absolute_currency == self.currency
      self.absolute_debit = self.real_debit
      self.absolute_credit = self.real_credit
    end
    if previous = self.previous
      self.cumulated_absolute_debit  = previous.cumulated_absolute_debit  + previous.absolute_debit
      self.cumulated_absolute_credit = previous.cumulated_absolute_credit + previous.absolute_credit
    end
  end

  validate(:on => :update) do
    old = self.class.find(self.id)
    errors.add(:account_id, :entry_has_been_already_validated) if old.closed?
    # Forbids to change "manually" the letter. Use Account#mark/unmark.
    errors.add(:letter, :invalid) if old.letter != self.letter and not (old.balanced_letter? and self.balanced_letter?)
  end

  #
  validate do
    unless self.updateable?
      errors.add(:number, :closed_entry)
      return
    end
    errors.add(:credit, :unvalid_amounts) if self.debit != 0 and self.credit != 0
  end

  before_update do
    old = self.old_record
    # Cancel old values if specific columns have been updated
    if self.absolute_debit != old.absolute_debit or self.absolute_credit != old.absolute_credit or self.printed_on != old.printed_on
      # old.followings.update_all("cumulated_absolute_debit = cumulated_absolute_debit - ?, cumulated_absolute_credit = cumulated_absolute_credit - ?", old.absolute_debit, old.absolute_debit)
      old.followings.update_all("cumulated_absolute_debit = cumulated_absolute_debit - #{old.absolute_debit.to_s}, cumulated_absolute_credit = cumulated_absolute_credit - #{old.absolute_debit}")
    end
  end

  after_save do
    # self.followings.update_all("cumulated_absolute_debit = cumulated_absolute_debit + ?, cumulated_absolute_credit = cumulated_absolute_credit + ?", self.absolute_debit, self.absolute_credit)
    self.followings.update_all("cumulated_absolute_debit = cumulated_absolute_debit + #{self.absolute_debit}, cumulated_absolute_credit = cumulated_absolute_credit + #{self.absolute_credit}")
  end

  protect(:on => :update) do
    not self.closed? and self.entry and self.entry.updateable?
  end

  protect(:on => :destroy) do
    !self.closed?
  end

  # Prints human name of current state
  def state_label
    ::I18n.t('models.journal_entry.states.'+self.state.to_s)
  end

  # updates the amounts to the debit and the credit
  # for the matching entry.
  def update_entry
    self.entry.refresh
  end


  # Returns the previous item
  def previous
    if self.new_record?
      self.account.journal_entry_items.order("printed_on, id").where("printed_on <= ?", self.printed_on).last
    else
      self.account.journal_entry_items.order("printed_on, id").where("(printed_on = ? AND id < ?) OR printed_on <= ?", self.printed_on, self.id, self.printed_on).last
    end
  end


  # Returns following items
  def followings
    if self.new_record?
      self.account.journal_entry_items.where("printed_on > ?", self.printed_on)
    else
      self.account.journal_entry_items.where("(printed_on = ? AND id > ?) OR printed_on > ?", self.printed_on, self.id, self.printed_on)
    end
  end


  # Unmark all the journal entry items with the same mark in the same account
  def unmark
    self.account.unmark(self.letter) unless self.letter.blank?
  end

#   # this method allows to lock the entry_item.
#   def close
#     self.update_column(:closed, true)
#   end

#   def reopen
#     self.update_column(:closed, false)
#   end

  # Check if the current letter is balanced with all entry items with the same letter
  def balanced_letter?
    return true if letter.blank?
    self.account.balanced_letter?(letter)
  end

  #this method allows to fix a display color if the entry_item is in draft mode.
  def mode
    mode=""
    mode+="warning" if self.draft?
    mode
  end

  #
  def resource
    if self.entry
      return self.entry.resource_type
    else
      'rien'
    end
  end

  # This method returns the name of journal which the entries are saved.
  def journal_name
    if self.entry
      return self.entry.journal.name
    else
      'rien'
    end
  end

  #this method:allows to fix a display color if the entry containing the entry_item is balanced or not.
  def balanced_entry
    return (self.entry.balanced? ? "balanced" : "unbalanced")
  end

  # this method creates a next entry_item with an initialized value matching to the previous entry.
  def next(balance)
    entry_item = JournalEntryItem.new
    if balance > 0
      entry_item.real_credit = balance.abs
    elsif balance < 0
      entry_item.real_debit  = balance.abs
    end
    return entry_item
  end

end

