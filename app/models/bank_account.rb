# == Schema Information
# Schema version: 20081127140043
#
# Table name: bank_accounts
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  agency       :string(255)   
#  counter      :string(16)    
#  number       :string(32)    
#  key          :string(4)     
#  iban         :string(34)    not null
#  iban_text    :string(48)    not null
#  bic          :string(16)    
#  bank_id      :integer       not null
#  journal_id   :integer       not null
#  currency_id  :integer       not null
#  account_id   :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class BankAccount < ActiveRecord::Base
  
  



end
