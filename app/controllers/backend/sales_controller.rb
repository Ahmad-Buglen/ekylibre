# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::SalesController < BackendController
  respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json
  include ActionView::Helpers::NumberHelper

  unroll_all

  # management -> sales_conditions
  def self.sales_conditions
    code = ""
    code = search_conditions(:sale, :sales => [:pretax_amount, :amount, :number, :initial_number, :description], :entities => [:code, :full_name]) + "||=[]\n"
    code << "unless session[:sale_state].blank?\n"
    code << "  if session[:sale_state] == 'current'\n"
    code << "    c[0] += \" AND state IN ('estimate', 'order', 'invoice')\"\n"
    # code << "  elsif session[:sale_state] == 'unpaid'\n"
    # code << "    c[0] += \" AND state IN ('order', 'invoice') AND paid_amount < amount AND lost = ?\"\n"
    # code << "    c << false\n"
    code << "  end\n "
    code << "  if session[:sale_responsible_id] > 0\n"
    code << "    c[0] += \" AND \#{Sale.table_name}.responsible_id = ?\"\n"
    code << "    c << session[:sale_responsible_id]\n"
    code << "  end\n"
    code << "end\n "
    code << "c\n "
    code
  end

  list(:conditions => sales_conditions, :joins => :client, :order => 'created_on desc, number desc') do |t| # , :line_class => 'RECORD.tags'
    t.column :number, :url => {:action => :show, :step => :default}
    t.column :created_on
    t.column :invoiced_on
    t.column :label, :through => :client, :url => true
    t.column :label, :through => :responsible
    t.column :description
    t.column :state_label
    t.column :amount, :currency => true
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit, :if => 'RECORD.draft? '
    t.action :cancel, :if => 'RECORD.cancelable? '
    t.action :destroy, :if => 'RECORD.aborted? '
  end

  # Displays the main page with the list of sales
  def index
    session[:sale_state] = params[:s] ||= params[:s]||"all"
    session[:sale_key] = params[:q]
    session[:sale_responsible_id] = params[:responsible_id].to_i
    @sales = Sale.where("state != ?", "draft")
    respond_to do |format|
      format.html
      format.xml  { render :xml => @sales }
      # format.pdf  { render_print_sales(params[:established_on]||Date.today) }
      format.pdf  { render :pdf => @sales, :with => params[:template] }
      # format.odt  { render_print_sales(params[:established_on]||Date.today) }
      # format.docx { render_print_sales(params[:established_on]||Date.today) }
    end
  end

  list(:credits, :model => :sales, :conditions => {:origin_id => ['session[:current_sale_id]'] }, :children => :items) do |t|
    t.column :number, :url => true, :children => :designation
    t.column :full_name, :through => :client, :children => false
    t.column :created_on, :children => false
    t.column :pretax_amount, :currency => {:body => true, :children => "RECORD.sale.currency"}
    t.column :amount, :currency => {:body => true, :children => "RECORD.sale.currency"}
  end

  list(:deliveries, :model => :outgoing_deliveries, :children => :items, :conditions => {:sale_id => ['session[:current_sale_id]']}) do |t|
    t.column :number, :children => :product_name
    t.column :last_name, :through => :transporter, :children => false, :url => true
    t.column :coordinate, :through => :address, :children => false
    t.column :planned_on, :children => false
    t.column :moved_on, :children => false
    t.column :quantity, :datatype => :decimal
    t.column :pretax_amount, :currency => {:body => "RECORD.sale.currency", :children => "RECORD.delivery.sale.currency"}
    t.column :amount, :currency => {:body => "RECORD.sale.currency", :children => "RECORD.delivery.sale.currency"}
    t.action :edit, :if => 'RECORD.sale.order? '
    t.action :destroy, :if => 'RECORD.sale.order? '
  end

  # list(:payment_uses, :model => :incoming_payment_uses, :conditions => ["#{IncomingPaymentUse.table_name}.expense_id=? AND #{IncomingPaymentUse.table_name}.expense_type=?", ['session[:current_sale_id]'], 'Sale']) do |t|
  #   t.column :number, :through => :payment, :url => true
  #   t.column :amount, :currency => "RECORD.payment.currency", :through => :payment, :label => "payment_amount", :url => true
  #   t.column :amount, :currency => "RECORD.payment.currency"
  #   t.column :payment_way
  #   t.column :scheduled, :through => :payment, :datatype => :boolean, :label => :column
  #   t.column :downpayment
  #   # t.column :paid_on, :through => :payment, :label => :column, :datatype => :date
  #   t.column :to_bank_on, :through => :payment, :label => :column, :datatype => :date
  #   t.action :destroy
  # end

  list(:subscriptions, :conditions => {:sale_id => ['session[:current_sale_id]']}) do |t|
    t.column :number
    t.column :name, :through => :nature
    t.column :full_name, :through => :entity, :url => true
    t.column :coordinate, :through => :address
    t.column :start
    t.column :finish
    t.column :quantity
    t.action :edit
    t.action :destroy
  end

  list(:undelivered_items, :model => :sale_items, :conditions => {:sale_id => ['session[:current_sale_id]'], :reduction_origin_id => nil}) do |t|
    t.column :name, :through => :product
    t.column :pretax_amount, :currency => "RECORD.price.currency", :through => :price
    t.column :quantity
    t.column :label, :through => :unit
    t.column :pretax_amount, :currency => "RECORD.price.currency"
    t.column :amount
    t.column :undelivered_quantity, :datatype => :decimal
  end

  list(:items, :model => :sale_items, :conditions => {:sale_id => ['params[:id]']}, :order => :position, :export => false, :line_class => "((RECORD.product.nature.subscribing? and RECORD.subscriptions.sum(:quantity) != RECORD.quantity) ? 'warning' : '')", :include => [:product, :subscriptions]) do |t|
    #t.column :name, :through => :product
    t.column :position
    t.column :label
    t.column :annotation
    t.column :serial_number, :through => :product, :url => true
    t.column :quantity
    t.column :label, :through => :unit
    t.column :pretax_amount, :through => :price, :label => "unit_price_amount", :currency => "RECORD.price.currency"
    t.column :pretax_amount, :currency => "RECORD.sale.currency"
    t.column :amount, :currency => "RECORD.sale.currency"
    t.action :edit, :if => 'RECORD.sale.draft? and RECORD.reduction_origin_id.nil? '
    t.action :destroy, :if => 'RECORD.sale.draft? and RECORD.reduction_origin_id.nil? '
  end

  # Displays details of one sale selected with +params[:id]+
  def show
    return unless @sale = find_and_check(:sale)
    respond_with(@sale, :methods => [:taxes_amount, :affair_closed, :client_number ],
                        :include => {:address => {:methods => [:mail_coordinate]},
                                     :supplier => {:methods => [:picture_path], :include => {:default_mail_address => {:methods => [:mail_coordinate]}}},
                                     :credits => {},
                                     :invoice_address => {:methods => [:mail_coordinate]},
                                     :items => {:methods => [:taxes_amount, :tax_name], :include => [:product, :price]}
                                     }
                                     ) do |format|
      format.html do
        session[:current_sale_id] = @sale.id
        session[:current_currency] = @sale.currency
        if params[:step] and not ["products", "deliveries", "summary"].include? params[:step]
          state  = @sale.state
          params[:step] = (@sale.invoice? ? :summary : @sale.order? ? :deliveries : :products).to_s
        end
        if params[:step] == "deliveries"
          if @sale.deliveries.size <= 0 and @sale.order? and @sale.has_content?
            redirect_to :controller => :outgoing_deliveries, :action => :new, :sale_id => @sale.id
          elsif @sale.deliveries.size <= 0 and @sale.invoice?
            notify(:sale_already_invoiced)
          elsif @sale.items.size <= 0
            notify_warning(:no_items_found)
            redirect_to :action => :show, :step => :products, :id => @sale.id
          end
        end
        t3e @sale.attributes, :client => @sale.client.full_name, :state => @sale.state_label, :label => @sale.label
      end
      # format.json { render :json => @sale, :include => {:items => {:include => :product}} }
      # format.xml  { render  :xml => @sale, :include => {:invoice_address => {}, :items => {:include => :product}} }
      # format.pdf  { render  :pdf => @sale, :include => {:items => {:include => :product}} }
      # format.odt  { render  :odt => @sale, :include => {:items => {:include => :product}} }
      # format.docx { render :docx => @sale, :include => {:items => {:include => :product}} }
      # # format.pdf do
      # #   if @sale.invoice?
      # #     render_print_sales_invoice(@sale)
      # #   else
      # #     render_print_sales_order(@sale)
      # #   end
      # # end
    end

  end

  def abort
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.abort
    end
    redirect_to :action => :show, :id => @sale.id
  end


  list(:creditable_items, :model => :sale_items, :conditions => ["sale_id=? AND reduction_origin_id IS NULL", ['session[:sale_id]']]) do |t|
    t.column :label
    t.column :annotation
    t.column :name, :through => :product
    t.column :amount, :through => :price, :label => :column
    t.column :quantity
    t.column :credited_quantity, :datatype => :decimal
    t.check_box  :validated, :value => "true", :label => 'OK'
    t.text_field :quantity, :value => "RECORD.uncredited_quantity", :size => 6
  end

  def cancel
    return unless @sale = find_and_check(:sale)
    session[:sale_id] = @sale.id
    if request.post?
      items = {}
      params[:creditable_items].select{|k,v| v[:validated].to_i == 1}.collect{ |k, v| items[k] = v[:quantity].to_f }
      if items.empty?
        notify_error_now(:need_quantities_to_cancel_an_sale)
        return
      end
      responsible = Entity.find_by_id(params[:sale][:responsible_id]) if params[:sale]
      if credit = @sale.cancel(items, :responsible => responsible||@current_user)
        redirect_to :action => :show, :id => credit.id
      end
    end
    t3e @sale.attributes
  end

  def confirm
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.confirm
    end
    redirect_to :action => :show, :step => :deliveries, :id => @sale.id
  end

  def contacts
    if request.xhr?
      client, address_id = nil, nil
      client = if params[:selected] and address = EntityAddress.find_by_id(params[:selected])
                 address.entity
               else
                 Entity.find_by_id(params[:client_id])
               end
      if client
        session[:current_entity_id] = client.id
        address_id = (address ? address.id : client.default_mail_address.id)
      end
      @sale = Sale.find_by_id(params[:sale_id])||Sale.new(:address_id => address_id, :delivery_address_id => address_id, :invoice_address_id => address_id)
      render :partial => 'addresses_form', :locals => {:client => client, :object => @sale}
    else
      redirect_to :action => :index
    end
  end

  def correct
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.correct
    end
    redirect_to :action => :show, :step => :products, :id => @sale.id
  end

  def new
    @sale = Sale.new(:nature => SaleNature.where(:id => params[:nature_id]).first)
    if client = Entity.find_by_id(params[:client_id]||params[:entity_id]||session[:current_entity_id])
      if client.default_mail_address
        cid = client.default_mail_address.id
        @sale.attributes = {:address_id => cid, :delivery_address_id => cid, :invoice_address_id => cid}
      end
    end
    session[:current_entity_id] = (client ? client.id : nil)
    @sale.responsible_id = current_user.id
    @sale.client_id = session[:current_entity_id]
    @sale.letter_format = false
    @sale.function_title = tg('letter_function_title')
    @sale.introduction = tg('letter_introduction')
    # @sale.conclusion = tg('letter_conclusion')
  end

  def create
    @sale = Sale.new(params[:sale])
    @sale.number = ''
    return if save_and_redirect(@sale, :url => {:action => :show, :step => :products, :id => "id"})
  end

  def destroy
    return unless @sale = find_and_check(:sale)
    if request.post? or request.delete?
      if @sale.aborted?
        @sale.destroy
      else
        notify_error(:sale_cant_be_deleted)
      end
    end
    redirect_to_current
  end

  def duplicate
    return unless sale = find_and_check(:sale)
    copy = nil
    begin
      copy = sale.duplicate(:responsible_id => @current_user.id)
    rescue Exception => e
      notify_error(:exception_raised, :message => e.message)
    end
    if copy
      redirect_to :action => :show, :step => :products, :id => copy.id
      return
    end
    redirect_to_current
  end

  def invoice
    return unless @sale = find_and_check(:sale)
    if request.post?
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @sale.invoice
        redirect_to :action => :show, :step => :summary, :id => @sale.id
        return
      end
    end
    redirect_to :action => :show, :step => :products, :id => @sale.id
  end

  def propose
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.propose
    end
    redirect_to :action => :show, :step => :products, :id => @sale.id
  end

  def propose_and_invoice
    return unless @sale = find_and_check(:sale)
    if request.post?
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @sale.propose
        raise ActiveRecord::Rollback unless @sale.confirm
        raise ActiveRecord::Rollback unless @sale.deliver
        raise ActiveRecord::Rollback unless @sale.invoice
      end
    end
    redirect_to :action => :show, :step => :summary, :id => @sale.id
  end

  def refuse
    return unless @sale = find_and_check(:sale)
    if request.post?
      @sale.refuse
    end
    redirect_to :action => :show, :step => :products, :id => @sale.id
  end

  def edit
    return unless @sale = find_and_check(:sale)
    unless @sale.draft?
      notify_error(:sale_cannot_be_updated)
      redirect_to :action => :show, :step => :products, :id => @sale.id
      return
    end
    t3e @sale.attributes
    # render_restfully_form
  end

  def update
    return unless @sale = find_and_check(:sale)
    unless @sale.draft?
      notify_error(:sale_cannot_be_updated)
      redirect_to :action => :show, :step => :products, :id => @sale.id
      return
    end
    if @sale.update_attributes(params[:sale])
      redirect_to :action => :show, :step => :products, :id => @sale.id
      return
    end
    t3e @sale.attributes
    # render_restfully_form
  end


  def statistics
    data = {}
    params[:states] ||= {}
    params[:states][:invoice] = 1 if params[:states].empty?
    params[:mode] ||= "pretax_amount"
    mode = params[:mode].to_s.to_sym
    if params[:utf8]
      states = params[:states].collect{|state, checked| state.to_sym if !checked.to_i.zero?}.compact
      query = "SELECT p.nature_id AS product_nature_id, sum(si.#{mode}) AS total FROM #{SaleItem.table_name} AS si JOIN #{Sale.table_name} AS s ON (si.sale_id=s.id) JOIN #{Product.table_name} AS p ON (si.product_id=p.id) WHERE "
      values = []
      cursors = {:invoice => :invoiced_on, :order => :confirmed_on}
      query << "(" + states.collect do |state|
        "(state = '#{state}' AND #{cursors[state] || :created_on} BETWEEN ? AND ?)"
      end.join(" OR ") + ")"
      query << " GROUP BY product_nature_id"
      start = (Date.today - params[:nb_years].to_i.year).beginning_of_month
      finish = Date.today.end_of_month
      date = start
      months = [] # [::I18n.t('activerecord.models.product')]
      # puts [start, finish].inspect
      while date <= finish
        period = '="'+t('date.abbr_month_names')[date.month]+" "+date.year.to_s+'"'
        months << period
        for product in ProductNature.find(:all, :select => "product_natures.*, total", :joins => ActiveRecord::Base.send(:sanitize_sql_array, ["LEFT JOIN (#{query}) AS sold ON (product_natures.id=product_nature_id)"] + [date.beginning_of_month, date.end_of_month] * states.size), :order => "product_nature_id")
          data[product.id.to_s] ||= {}
          data[product.id.to_s][period] = product.total.to_f
        end
        date += 1.month
      end

      csv_data = Ekylibre::CSV.generate do |csv|
        csv << [ProductNature.model_name.human, ProductNature.human_attribute_name(:number), ProductNature.human_attribute_name('product_account_id')]+months
        for product in ProductNature.order(:name)
          valid = false
          for period, amount in data[product.id.to_s]
            valid = true if amount != 0
          end
          if product.active or valid
            row = [product.name, product.number, (product.product_account ? product.product_account.number : "?")]
            months.size.times do |i|
              if data[product.id.to_s][months[i]].zero?
                row << ''
              else
                row << number_to_currency(data[product.id.to_s][months[i]], :separator => ',', :delimiter => ' ', :unit => '', :precision => 2)
              end
            end
            csv << row
          end
        end
      end

      send_data csv_data, :type => Mime::CSV, :disposition => 'inline', :filename => "#{human_action_name}.csv"
    end
  end

end
