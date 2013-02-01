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
# == Table: product_groups
#
#  color        :string(255)      
#  created_at   :datetime         not null
#  creator_id   :integer          
#  depth        :integer          default(0), not null
#  description  :text             
#  id           :integer          not null, primary key
#  lft          :integer          
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  parent_id    :integer          
#  rgt          :integer          
#  updated_at   :datetime         not null
#  updater_id   :integer          
#
require 'test_helper'

class ProductGroupTest < ActiveSupport::TestCase

  # Replace this with your real tests.'
  test "the truth" do
    assert true
  end

end
