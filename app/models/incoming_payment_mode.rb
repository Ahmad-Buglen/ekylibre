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
# == Table: incoming_payment_modes
#
#  active                  :boolean
#  attorney_journal_id     :integer
#  cash_id                 :integer
#  commission_account_id   :integer
#  commission_base_amount  :decimal(19, 4)   default(0.0), not null
#  commission_percentage   :decimal(19, 4)   default(0.0), not null
#  created_at              :datetime         not null
#  creator_id              :integer
#  depositables_account_id :integer
#  depositables_journal_id :integer
#  detail_payments         :boolean          not null
#  id                      :integer          not null, primary key
#  lock_version            :integer          default(0), not null
#  name                    :string(50)       not null
#  position                :integer
#  updated_at              :datetime         not null
#  updater_id              :integer
#  with_accounting         :boolean          not null
#  with_commission         :boolean          not null
#  with_deposit            :boolean          not null
#


class IncomingPaymentMode < Ekylibre::Record::Base
  attr_accessible :cash_id, :attorney_journal, :attorney_journal_id, :commission_account_id, :commission_base_amount, :commission_percentage, :depositables_account_id, :depositables_journal_id, :detail_payments, :name, :position, :with_accounting, :with_commission, :with_deposit
  attr_readonly :cash_id, :cash
  acts_as_list
  belongs_to :attorney_journal, :class_name => "Journal"
  belongs_to :cash
  belongs_to :commission_account, :class_name => "Account"
  belongs_to :depositables_account, :class_name => "Account"
  belongs_to :depositables_journal, :class_name => "Journal"
  has_many :depositable_payments, :class_name => "IncomingPayment", :foreign_key => :mode_id, :conditions => {:deposit_id => nil}
  has_many :entities, :dependent => :nullify, :foreign_key => :payment_mode_id
  has_many :payments, :foreign_key => :mode_id, :class_name => "IncomingPayment"
  has_many :unlocked_payments, :foreign_key => :mode_id, :class_name => "IncomingPayment", :conditions => 'journal_entry_id IN (SELECT id FROM #{JournalEntry.table_name} WHERE state=#{connection.quote("draft")})'
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :commission_base_amount, :commission_percentage, :allow_nil => true
  validates_length_of :name, :allow_nil => true, :maximum => 50
  validates_inclusion_of :detail_payments, :with_accounting, :with_commission, :with_deposit, :in => [true, false]
  validates_presence_of :commission_base_amount, :commission_percentage, :name
  #]VALIDATORS]
  validates_numericality_of :commission_percentage, :greater_than_or_equal_to => 0, :if => :with_commission?
  validates_presence_of :attorney_journal, :if => :with_accounting?
  validates_presence_of :depositables_account, :if => :with_deposit?
  validates_presence_of :cash

  delegate :currency, :to => :cash

  default_scope -> { order(:position) }
  scope :depositers, -> { where(:with_deposit => true).order(:name) }

  before_validation do
    if self.cash and self.cash.cash_box?
      self.with_deposit = false
      self.with_commission = false
    end
    unless self.with_deposit?
      self.depositables_account = nil
      self.depositables_journal = nil
    end
    unless self.with_commission
      self.commission_base_amount ||= 0
      self.commission_percentage ||= 0
    end

    return true
  end

  protect(:on => :destroy) do
    self.payments.count <= 0
  end

  def commission_amount(amount)
    return (amount * self.commission_percentage * 0.01 + self.commission_base_amount).round(2)
  end

end
