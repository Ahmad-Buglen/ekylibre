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
# == Table: observations
#
#  author_id    :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  description  :text             not null
#  id           :integer          not null, primary key
#  importance   :string(10)       not null
#  lock_version :integer          default(0), not null
#  observed_at  :datetime         not null
#  owner_id     :integer          not null
#  owner_type   :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Observation < Ekylibre::Record::Base
  attr_accessible :author_id, :importance, :description, :owner_id, :owner_type
  enumerize :importance, :in => [:important, :normal, :notice], :default => :notice, :predicates => true
  belongs_to :owner, :polymorphic => true
  belongs_to :author, :class_name => "User"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :importance, :allow_nil => true, :maximum => 10
  validates_length_of :owner_type, :allow_nil => true, :maximum => 255
  validates_presence_of :author, :description, :importance, :observed_at, :owner, :owner_type
  #]VALIDATORS]

  before_validation do
    self.importance ||= self.class.importance.default_value
  end

end
