# encoding:UTF-8
require 'test_helper'

class AddANewAnimalTest < CapybaraIntegrationTest

  setup do
    visit('/authentication/sign_in')
    shoot_screen "authentication/sign_in"
    login_as(users(:users_001), scope: :user)
    visit('/backend')
    shoot_screen "backend"
  end

  # Add a cow
  test "add an animal" do
    visit('/backend/animals/new?variant_id=7')
    shoot_screen "animals/new"
    select('Bovin', from: 'animal[variety]')
    fill_in('animal[name]', with: 'Linette')
    fill_in("animal[work_number]", with: '9253')
    fill_in("animal[identification_number]", with: 'FR17129253')
    fill_unroll("animal-mother-input", with: "isa", select: "Isabelle", name: :animals)
    attach_file('animal[picture]', Rails.root.join("test", "fixtures", "files", "animals-ld", "cow-8580.jpg"))
    shoot_screen "animals/new-before_create"
    click_on("Créer")
    shoot_screen "animals/new-after_create"
    visit('/backend/animals')
    assert has_content?('Linette'), "Linette must appear in animals list after its creation"
  end

  # View a cow
  test "view an animal" do
    visit ('/backend/animals')
    shoot_screen "animals/index"
    assert has_content?('Marguerite'), "Marguerite must appear in animals list"
    click_link 'Marguerite'
    shoot_screen "animals/show-marguerite"
    assert has_content?('female'), "Marguerite should appear as a female"
  end

  # Add an issue on the current animal
  test "add an issue" do
    visit('/backend/issues/new?target_id=7004&target_type=Animal')
    shoot_screen "issues/new"
    fill_in('issue[name]', with: "3ème mammite de l'année")
    select('Mammite', from: 'issue[nature]')
    fill_in("issue_observed_at", with: '01/06/2013')
    choose("issue_priority_1")
    choose("issue_gravity_3")
    click_on("Créer")
    shoot_screen "issues/create"
  end

  test "view an issue on an animal" do
    visit ('/backend/issues')
    shoot_screen "issues/index"
  end

end
