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
# == Table: products
#
#  address_id            :integer
#  born_at               :datetime
#  category_id           :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  dead_at               :datetime
#  default_storage_id    :integer
#  derivative_of         :string(120)
#  description           :text
#  extjuncted            :boolean          not null
#  financial_asset_id    :integer
#  id                    :integer          not null, primary key
#  identification_number :string(255)
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_mother_id     :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :spatial({:srid=>
#  lock_version          :integer          default(0), not null
#  name                  :string(255)      not null
#  nature_id             :integer          not null
#  number                :string(255)      not null
#  parent_id             :integer
#  person_id             :integer
#  picture_content_type  :string(255)
#  picture_file_name     :string(255)
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  tracking_id           :integer
#  type                  :string(255)
#  updated_at            :datetime         not null
#  updater_id            :integer
#  variant_id            :integer          not null
#  variety               :string(120)      not null
#  work_number           :string(255)
#
class Plant < Bioproduct
  enumerize :variety, in: Nomen::Varieties.all(:plant), predicates: {prefix: true}

  has_shape

  #return all Plant object who is alive in the considers campaigns
  scope :of_campaign, lambda { |campaign|
    raise ArgumentError.new("Expected Campaign, got #{campaign.class.name}:#{campaign.inspect}") unless campaign.is_a?(Campaign)
    stopped_at = Date.new(campaign.harvest_year.to_f, 12, 31)
    where('(dead_at <= ? OR dead_at IS NULL)', stopped_at)
  }

end
