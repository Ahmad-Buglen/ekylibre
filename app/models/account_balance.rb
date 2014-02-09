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
# == Table: account_balances
#
#  account_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string(255)      not null
#  financial_year_id :integer          not null
#  global_balance    :decimal(19, 4)   default(0.0), not null
#  global_count      :integer          default(0), not null
#  global_credit     :decimal(19, 4)   default(0.0), not null
#  global_debit      :decimal(19, 4)   default(0.0), not null
#  id                :integer          not null, primary key
#  local_balance     :decimal(19, 4)   default(0.0), not null
#  local_count       :integer          default(0), not null
#  local_credit      :decimal(19, 4)   default(0.0), not null
#  local_debit       :decimal(19, 4)   default(0.0), not null
#  lock_version      :integer          default(0), not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#


class AccountBalance < Ekylibre::Record::Base
  belongs_to :account
  belongs_to :financial_year
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :global_balance, :global_credit, :global_debit, :local_balance, :local_credit, :local_debit, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 255
  validates_presence_of :account, :currency, :financial_year, :global_balance, :global_credit, :global_debit, :local_balance, :local_credit, :local_debit
  #]VALIDATORS]
  validates_uniqueness_of :account_id, :scope => :financial_year_id

  alias_attribute :debit, :local_debit
  alias_attribute :credit, :local_credit
  alias_attribute :balance, :local_balance
  alias_attribute :journal_entry_items_count, :local_count

  before_validation do
    self.balance = self.debit - self.credit
  end

  def balance_debit
    return (self.balance > 0 ? self.balance.abs : 0)
  end

  def balance_credit
    return (self.balance > 0 ? 0 : self.balance.abs)
  end

end
