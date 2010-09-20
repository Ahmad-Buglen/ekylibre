# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
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
# == Table: cash_transfers
#
#  accounted_at     :datetime         
#  amount           :decimal(16, 2)   default(0.0), not null
#  comment          :text             
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  currency_amount  :decimal(16, 2)   default(0.0), not null
#  currency_id      :integer          not null
#  currency_rate    :decimal(16, 6)   default(1.0), not null
#  emitter_cash_id  :integer          not null
#  id               :integer          not null, primary key
#  journal_entry_id :integer          
#  lock_version     :integer          default(0), not null
#  number           :string(255)      not null
#  receiver_cash_id :integer          not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#

class CashTransfer < ActiveRecord::Base
end
