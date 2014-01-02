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
# == Table: accounts
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  debtor       :boolean          not null
#  description  :text
#  id           :integer          not null, primary key
#  label        :string(255)      not null
#  last_letter  :string(10)
#  lock_version :integer          default(0), not null
#  name         :string(200)      not null
#  number       :string(20)       not null
#  reconcilable :boolean          not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#  usages       :text
#
require 'test_helper'

class AccountTest < ActiveSupport::TestCase

  test "load the charts" do
    # for locale in I18n.available_locales
    #   I18n.locale = locale
    #   assert_equal I18n.locale, locale
    #   charts = Account.charts
    #   for chart in charts
    #     Account.load_chart(chart)
    #   end
    # end
  end

end
