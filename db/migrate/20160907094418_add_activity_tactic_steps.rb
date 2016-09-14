class AddActivityTacticSteps < ActiveRecord::Migration
  def change
    create_table :activity_tactic_steps do |t|
      t.references :tactic, null: false, index: true
      t.string :name, null: false
      t.date :started_on, null: false
      t.date :stopped_on, null: false
      t.string :procedure_categorie, null: false
      t.string :procedure_name
      t.string :action
      t.stamps
    end
  end
end
