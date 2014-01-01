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
# == Table: analytic_repartitions
#
#  affectation_percentage :decimal(19, 4)   not null
#  affected_on            :date             not null
#  created_at             :datetime         not null
#  creator_id             :integer
#  id                     :integer          not null, primary key
#  journal_entry_item_id  :integer          not null
#  lock_version           :integer          default(0), not null
#  production_id          :integer          not null
#  state                  :string(255)      not null
#  updated_at             :datetime         not null
#  updater_id             :integer
#
class AnalyticRepartition < Ekylibre::Record::Base
  # attr_accessible :state, :production_id, :affected_on,  :description, :journal_entry_item_id,  :percentage
  belongs_to :production
  belongs_to :journal_entry_item

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :affectation_percentage, allow_nil: true
  validates_length_of :state, allow_nil: true, maximum: 255
  validates_presence_of :affectation_percentage, :affected_on, :journal_entry_item, :production, :state
  #]VALIDATORS]

  state_machine :state, :initial => :draft do
    state :draft
    state :confirmed
    state :closed
  end

  # default_scope -> { order(:name) }


end
