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
# == Table: users
#
#  administrator                          :boolean          default(TRUE), not null
#  arrived_on                             :date
#  authentication_token                   :string(255)
#  commercial                             :boolean
#  confirmation_sent_at                   :datetime
#  confirmation_token                     :string(255)
#  confirmed_at                           :datetime
#  created_at                             :datetime         not null
#  creator_id                             :integer
#  current_sign_in_at                     :datetime
#  current_sign_in_ip                     :string(255)
#  departed_on                            :date
#  department_id                          :integer
#  description                            :text
#  email                                  :string(255)      not null
#  employed                               :boolean          not null
#  employment                             :string(255)
#  encrypted_password                     :string(255)      default(""), not null
#  entity_id                              :integer
#  establishment_id                       :integer
#  failed_attempts                        :integer          default(0)
#  first_name                             :string(255)      not null
#  id                                     :integer          not null, primary key
#  language                               :string(3)        default("???"), not null
#  last_name                              :string(255)      not null
#  last_sign_in_at                        :datetime
#  last_sign_in_ip                        :string(255)
#  lock_version                           :integer          default(0), not null
#  locked                                 :boolean          not null
#  locked_at                              :datetime
#  maximal_grantable_reduction_percentage :decimal(19, 4)   default(5.0), not null
#  office                                 :string(255)
#  profession_id                          :integer
#  remember_created_at                    :datetime
#  reset_password_sent_at                 :datetime
#  reset_password_token                   :string(255)
#  rights                                 :text
#  role_id                                :integer          not null
#  sign_in_count                          :integer          default(0)
#  unconfirmed_email                      :string(255)
#  unlock_token                           :string(255)
#  updated_at                             :datetime         not null
#  updater_id                             :integer
#
require 'test_helper'

class UserTest < ActiveSupport::TestCase
end
