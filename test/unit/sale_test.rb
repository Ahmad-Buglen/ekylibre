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
# == Table: sales
#
#  accounted_at        :datetime
#  address_id          :integer
#  affair_id           :integer
#  amount              :decimal(19, 4)   default(0.0), not null
#  annotation          :text
#  client_id           :integer          not null
#  conclusion          :text
#  confirmed_on        :date
#  created_at          :datetime         not null
#  created_on          :date             not null
#  creator_id          :integer
#  credit              :boolean          not null
#  currency            :string(3)
#  delivery_address_id :integer
#  description         :text
#  downpayment_amount  :decimal(19, 4)   default(0.0), not null
#  expiration_delay    :string(255)
#  expired_on          :date
#  function_title      :string(255)
#  has_downpayment     :boolean          not null
#  id                  :integer          not null, primary key
#  initial_number      :string(64)
#  introduction        :text
#  invoice_address_id  :integer
#  invoiced_on         :date
#  journal_entry_id    :integer
#  letter_format       :boolean          default(TRUE), not null
#  lock_version        :integer          default(0), not null
#  nature_id           :integer
#  number              :string(64)       not null
#  origin_id           :integer
#  payment_delay       :string(255)      not null
#  payment_on          :date
#  pretax_amount       :decimal(19, 4)   default(0.0), not null
#  reference_number    :string(255)
#  responsible_id      :integer
#  state               :string(64)       not null
#  subject             :string(255)
#  sum_method          :string(8)        default("wt"), not null
#  transporter_id      :integer
#  updated_at          :datetime         not null
#  updater_id          :integer
#


require 'test_helper'

class SaleTest < ActiveSupport::TestCase

  context "A minimal configuration" do

    setup do
      DocumentTemplate.load_defaults(:locale => :fra)
      DocumentTemplate.update_all({:to_archive => true}, {:nature => "sales_invoice"})
    end

    context "A sale" do

      setup do
        @sale = sales(:sales_001)
        assert @sale.draft?
        assert @sale.save
      end

      should "be invoiced" do
        assert !@sale.invoice

        item = @sale.items.new(:quantity => 12, :product_id => products(:animals_001).id) # :price_id => product_nature_prices(:product_nature_prices_001).id) # , :warehouse_id => products(:warehouses_001).id)
        assert item.save, item.errors.inspect
        item = @sale.items.new(:quantity => 25, :product_id => products(:matters_001).id) # :price_id => product_nature_prices(:product_nature_prices_003).id) # , :warehouse_id => products(:warehouses_001).id)
        assert item.save, item.errors.inspect
        @sale.reload
        assert_equal "draft", @sale.state
        assert @sale.propose
        assert_equal "estimate", @sale.state
        assert !@sale.can_invoice?, "Deliverables: " + @sale.items.collect{|l| l.product.attributes.inspect}.to_sentence
        assert @sale.confirm
        assert @sale.invoice
        assert_equal "invoice", @sale.state
      end

      should "be printed" do
        DocumentTemplate.print(:sales_order, :sales_order => @sale)
        assert_nothing_raised do
          DocumentTemplate.print(:sales_order, :sales_order => @sale)
          # @company.print(:id => :sales_order, :sales_order => @sale)
        end
      end

    end

    context "A sales invoice" do

      setup do
        @sale = Sale.new(:client => entities(:entities_001), :nature => sale_natures(:sale_natures_001))
        assert @sale.save, @sale.errors.inspect
        assert_equal Date.today, @sale.created_on
        assert !@sale.affair.nil?, "A sale must be linked to an affair"
        assert_equal @sale.amount, @sale.affair_credit, "Affair amount is not the same as the sale amount (#{@sale.affair.inspect})"

        for y in 1..10
          item = @sale.items.new(:quantity => 1 + rand(70)*rand, :product_id => products("matters_#{(3+rand(2)).to_s.rjust(3, '0')}".to_sym).id) # , :price_id => product_nature_prices("product_nature_prices_#{(3+rand(2)).to_s.rjust(3, '0')}".to_sym).id, :warehouse_id => products(:warehouses_001).id)
          # assert item.valid?, [product.prices, item.price].inspect
          assert item.save, item.errors.inspect
        end
        @sale.reload
        assert_equal "draft", @sale.state
        assert @sale.propose
        assert_equal "estimate", @sale.state
        assert !@sale.can_invoice?, "Deliverables: " + @sale.items.collect{|l| l.product.attributes.inspect}.to_sentence
        assert @sale.confirm
        assert @sale.invoice
        assert_equal "invoice", @sale.state
        assert_equal Date.today, @sale.invoiced_on
      end

      should "not be updateable" do
        amount = @sale.amount
        assert_raise ActiveModel::MassAssignmentSecurity::Error do
          @sale.update_attributes(:amount => amount.to_i+50)
        end
        @sale.reload
        assert_equal amount, @sale.amount, "State of sale is: #{@sale.state}"
      end

      should "be printed and archived" do
        data = []

        DocumentTemplate.print(:sales_invoice, :sales_invoice => @sale)

        assert_nothing_raised do
          data << Digest::SHA256.hexdigest(DocumentTemplate.print(:sales_invoice, :sales_invoice => @sale)[0])
        end
        assert_nothing_raised do
          data << Digest::SHA256.hexdigest(DocumentTemplate.print(:sales_invoice, :sales_invoice => @sale)[0])
        end
        assert_nothing_raised do
          data << Digest::SHA256.hexdigest(DocumentTemplate.print(:sales_invoice, :sales_invoice => @sale)[0])
        end
        assert_equal data[0], data[1], "The template doesn't seem to be archived"
        assert_equal data[0], data[2], "The template doesn't seem to be archived or understand Integers"
      end

    end
  end
end
