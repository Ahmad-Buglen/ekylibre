# == Schema Information
#
# Table name: currencies
#
#  active       :boolean       default(TRUE), not null
#  code         :string(255)   not null
#  comment      :text          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  format       :string(16)    not null
#  id           :integer       not null, primary key
#  lock_version :integer       default(0), not null
#  name         :string(255)   not null
#  rate         :decimal(16, 6 default(1.0), not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Currency < ActiveRecord::Base
  belongs_to :company

  has_many :bank_accounts
  has_many :entries
  has_many :journals
  has_many :prices

  def symbol
    return "€" 
  end


end
