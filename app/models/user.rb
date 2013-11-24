# -*- coding: utf-8 -*-
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
#  commercial                             :boolean          not null
#  confirmation_sent_at                   :datetime
#  confirmation_token                     :string(255)
#  confirmed_at                           :datetime
#  created_at                             :datetime         not null
#  creator_id                             :integer
#  current_sign_in_at                     :datetime
#  current_sign_in_ip                     :string(255)
#  departed_at                            :datetime
#  description                            :text
#  email                                  :string(255)      not null
#  employed                               :boolean          not null
#  employment                             :string(255)
#  encrypted_password                     :string(255)      default(""), not null
#  establishment_id                       :integer
#  failed_attempts                        :integer          default(0)
#  first_name                             :string(255)      not null
#  id                                     :integer          not null, primary key
#  language                               :string(3)        not null
#  last_name                              :string(255)      not null
#  last_sign_in_at                        :datetime
#  last_sign_in_ip                        :string(255)
#  lock_version                           :integer          default(0), not null
#  locked                                 :boolean          not null
#  locked_at                              :datetime
#  maximal_grantable_reduction_percentage :decimal(19, 4)   default(5.0), not null
#  office                                 :string(255)
#  person_id                              :integer
#  remember_created_at                    :datetime
#  reset_password_sent_at                 :datetime
#  reset_password_token                   :string(255)
#  rights                                 :text
#  role_id                                :integer          not null
#  sign_in_count                          :integer          default(0)
#  team_id                                :integer
#  unconfirmed_email                      :string(255)
#  unlock_token                           :string(255)
#  updated_at                             :datetime         not null
#  updater_id                             :integer
#

class User < Ekylibre::Record::Base
  # attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :employed
  attr_readonly :person_id
  belongs_to :team
  belongs_to :establishment
  belongs_to :person
  belongs_to :role
  # belongs_to :profession
  # has_many :events, class_name: "Event" #, foreign_key: :responsible_id
  # has_many :future_events, class_name: "Event", :conditions => ["started_at >= CURRENT_TIMESTAMP"] # , foreign_key: :responsible_id
  has_many :preferences, dependent: :destroy, foreign_key: :user_id
  has_many :sales_invoices, -> { where(:state => "invoice") }, foreign_key: :responsible_id, class_name: "Sale"
  has_many :sales, class_name: "Sale", foreign_key: :responsible_id
  has_many :transports, class_name: "Transport", foreign_key: :responsible_id
  has_many :unpaid_sales, -> { order("created_on").where("state IN ('order', 'invoice') AND paid_amount < amount AND lost = ? ", false) }, class_name: "Sale", foreign_key: :responsible_id

  scope :employees, -> { where(:employed => true) }

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :failed_attempts, allow_nil: true, only_integer: true
  validates_numericality_of :maximal_grantable_reduction_percentage, allow_nil: true
  validates_length_of :language, allow_nil: true, maximum: 3
  validates_length_of :authentication_token, :confirmation_token, :current_sign_in_ip, :email, :employment, :encrypted_password, :first_name, :last_name, :last_sign_in_ip, :office, :reset_password_token, :unconfirmed_email, :unlock_token, allow_nil: true, maximum: 255
  validates_inclusion_of :administrator, :commercial, :employed, :locked, in: [true, false]
  validates_presence_of :email, :encrypted_password, :first_name, :language, :last_name, :maximal_grantable_reduction_percentage, :role
  #]VALIDATORS]
  # validates_presence_of :password, :password_confirmation, if: Proc.new{|e| e.encrypted_password.blank? and e.loggable?}
  validates_confirmation_of :password
  validates_numericality_of :maximal_grantable_reduction_percentage, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100
  validates_uniqueness_of :email
  # validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, if: lambda{|r| !r.email.blank?}

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :registerable
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  model_stamper # Needed to stamp.all records
  delegate :picture, :full_name, :participations, to: :person

  class << self
    def rights_file; Rails.root.join("config", "rights.yml"); end
    def minimum_right; :__minimum__; end
    def rights; @@rights; end
    def rights_list; @@rights_list; end
  end

  before_validation do
    self.maximal_grantable_reduction_percentage ||= 0
    self.rights_array = self.rights_array # Clean the rights
  end

  before_save do
    unless self.person
      person = Person.create!(:first_name => self.first_name, :last_name => self.last_name, :nature => Person.nature.default_value)
      self.person_id = person.id
    end
  end

  def label
    self.full_name
  end

  def rights_array
    self.rights.to_s.split(/\s+/).collect{|x| x.to_sym}
  end

  def rights_array=(array)
    narray = array.select{|x| self.class.rights_list.include? x.to_sym}.collect{|x| x.to_sym}
    self.rights = narray.join(" ")
    return narray
  end

  def diff_more(right_markup = 'div', separator='')
    return '<div>&infin;</div>'.html_safe if self.administrator?
    (self.rights_array-self.role.rights_array).select{|x| self.class.rights_list.include?(x)}.collect{|x| "<#{right_markup}>"+::I18n.t("rights.#{x}")+"</#{right_markup}>"}.join(separator).html_safe
  end


  def diff_less(right_markup = 'div', separator='')
    return '' if self.administrator?
    (self.role.rights_array-self.rights_array).select{|x| self.class.rights_list.include?(x)}.collect{|x| "<#{right_markup}>"+::I18n.t("rights.#{x}")+"</#{right_markup}>"}.join(separator).html_safe
  end


  # Find or create preference for given name
  def preference(name, value = nil, nature = :string)
    unless p = self.preferences.reorder(:id).find_by(name: name)
      p = self.preferences.build
      p.name   = name
      p.nature = nature.to_s
      p.value  = value
      p.save!
    end
    return p
  end
  alias :pref :preference

  # # Find and check user account
  # def self.authenticate(user_name, password)
  #   if user = self.find_by_user_name_and_loggable(user_name.to_s.downcase, true)
  #     if user.locked or !user.authenticated?(password.to_s)
  #       user = nil
  #     end
  #   end
  #   return user
  # end

  def authorization(controller_name, action_name, rights_list=nil)
    rights_list = self.rights_array if rights_list.blank?
    message = nil
    if self.class.rights[controller_name.to_sym].nil?
      message = tc(:no_right_defined_for_this_part_of_the_application, :controller => controller_name, :action => action_name)
    elsif (rights = self.class.rights[controller_name.to_sym][action_name.to_sym]).nil?
      message = tc(:no_right_defined_for_this_part_of_the_application, :controller => controller_name, :action => action_name)
    elsif (rights & [:__minimum__, :__public__]).empty? and (rights_list & rights).empty? and not self.administrator?
      message = tc(:no_right_defined_for_this_part_of_the_application_and_this_user)
    end
    return message
  end

  def can?(right)
    self.administrator? or self.rights.match(/(^|\s)#{right}(\s|$)/)
  end

  protect(on: :destroy) do
    self.class.count > 1
  end

  # def authenticated?(password)
  #   self.hashed_password == self.class.encrypted_password(password, self.salt)
  # end

  # Used for generic password creation
  def self.give_password(length=8, mode=:complex)
    self.generate_password(length, mode)
  end

  private

  # def self.encrypted_password(password, salt)
  #   string_to_hash = "<"+password.to_s+":"+salt.to_s+"/>"
  #   Digest::SHA256.hexdigest(string_to_hash)
  # end

  def self.generate_password(password_length=8, mode=:normal)
    return '' if password_length.blank? or password_length<1
    case mode
    when :dummy then
      letters = %w(a b c d e f g h j k m n o p q r s t u w x y 3 4 6 7 8 9)
    when :simple then
      letters = %w(a b c d e f g h j k m n o p q r s t u w x y A B C D E F G H J K M N P Q R T U W Y X 3 4 6 7 8 9)
    when :normal then
      letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9)
    else
      letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9 _ = + - * | [ ] { } . : ; ! ? , § % / & < >)
    end
    letters_length = letters.length
    password = ''
    password_length.times{password+=letters[(letters_length*rand).to_i]}
    password
  end


  def self.initialize_rights
    definition = YAML.load_file(self.rights_file)
    @@rights_list = definition.keys.sort.delete_if{|k| k.match(/^__.*__$/)}.map(&:to_sym)
    @@rights = HashWithIndifferentAccess.new
    for right, actions in definition
      for uniq_action in actions
        controller, action = uniq_action.split(/\#/)[0..1]
        @@rights[controller] ||= HashWithIndifferentAccess.new
        @@rights[controller][action] ||= []
        @@rights[controller][action] << right.to_sym
      end if actions.is_a? Array
    end
  end

  initialize_rights

end
