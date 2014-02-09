class Backend::Cells::LastSalesCellsController < Backend::CellsController

  list(:model => :sales,:order => "created_at DESC", :per_page => 5) do |t|
    t.column :number, :url => {controller: "/backend/sales"}
    t.column :created_at
    #t.column :payment_delay
    t.status
    t.column :state_label
    t.column :amount, currency: true
  end


  def show

  end

end
