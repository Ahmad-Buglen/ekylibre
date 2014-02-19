# -*- coding: utf-8 -*-
load_data :animals do |loader|

  # find animals credentials in preferences
  cattling_root_number = Identifier.find_by_nature(:cattling_root_number).value

  groups = []

  file = loader.path("alamano", "animal_groups.csv")
  if file.exist?
    loader.count :animal_groups do |w|
      CSV.foreach(file, headers: true) do |row|
        r = OpenStruct.new(name: row[0],
                           nature: row[1].to_sym,
                           member_nature: row[2].to_sym,
                           code: row[3],
                           minimum_age: (row[4].blank? ? nil : row[4].to_i),
                           maximum_age: (row[5].blank? ? nil : row[5].to_i),
                           sex: (row[6].blank? ? nil : row[6].to_sym),
                           place: (row[7].blank? ? nil : row[7].to_sym),
                           description: row[8].to_s,
                           record: nil
                           )


        unless r.record = AnimalGroup.find_by_work_number(r.code)
          r.record = AnimalGroup.create!(name: r.name,
                                         work_number: r.code,
                                         variant: ProductNatureVariant.import_from_nomenclature(r.nature),
                                         default_storage: BuildingDivision.find_by(work_number: r.place),
                                         description: r.description)
        end

        groups << r
        w.check_point
      end
    end
  end

  male_adult_cow   = ProductNatureVariant.import_from_nomenclature(:male_adult_cow)
  female_adult_cow = ProductNatureVariant.import_from_nomenclature(:female_adult_cow)
  place   = BuildingDivision.last # find_by_work_number("B07_D2")

  file = loader.path("alamano", "liste_males_reproducteurs.txt")
  if file.exist?
    loader.count :upra_reproductor_list_import do |w|
      now = Time.now - 2.months
      CSV.foreach(file, encoding: "CP1252", col_sep: "\t", headers: true) do |row|
        next if row[4].blank?
        r = OpenStruct.new(:order => row[0],
                           :name => row[1],
                           :identification_number => row[2],
                           :work_number => row[2][-4..-1],
                           :father => row[3],
                           :provider => row[4],
                           :isu => row[5].to_i,
                           :inel => row[9].to_i,
                           :tp => row[10].to_f,
                           :tb => row[11].to_f
                           )
        animal = Animal.create!(:variant_id => male_adult_cow.id, :name => r.name, :variety => "bos", :identification_number => r.identification_number[-10..-1], :initial_owner => Entity.where(:of_company => false).all.sample)
        # set default indicators
        animal.read!(:unique_synthesis_index,         r.isu.in_unity,  at: now)
        animal.read!(:economical_milk_index,          r.inel.in_unity, at: now)
        animal.read!(:protein_concentration_index,    r.tp.in_unity,   at: now)
        animal.read!(:fat_matter_concentration_index, r.tb.in_unity,   at: now)
        # put in an external localization
        animal.localizations.create!(nature: :exterior)
        w.check_point
      end
    end
  end

  # attach picture if exist for each group
  for group in AnimalGroup.all
    picture_path = loader.path("alamano", "animal_groups_pictures", "#{group.work_number}.jpg")
    f = (picture_path.exist? ? File.open(picture_path) : nil)
    if f
      group.picture = f
      group.save!
      f.close
    end
  end

  # build name of synel animals file
  if loader.manifest[:net_services][:synel]
    synel_first_part = loader.manifest[:net_services][:synel][:synel_username].to_s
    synel_second_part = loader.manifest[:identifiers][:cattling_number].to_s
    synel_last_part = "IP"
    synel_file_extension = ".csv"
    if synel_first_part and synel_second_part
      synel_file_name = synel_first_part + synel_second_part + synel_last_part + synel_file_extension
    end
  else synel_file_name = "animaux.csv"
  end

  file = loader.path("synel", synel_file_name.to_s)
  if file.exist?
    now = Time.now
    loader.count :synel_animal_import do |w|
      #############################################################################

      CSV.foreach(file, encoding: "CP1252", col_sep: ";", headers: true) do |row|
        next if row[4].blank?
        born_on = (row[4].blank? ? nil : Date.civil(*row[4].to_s.split(/\//).reverse.map(&:to_i)))
        dead_on = (row[10].blank? ? nil : Date.civil(*row[10].to_s.split(/\//).reverse.map(&:to_i)))
        r = OpenStruct.new(:country => row[0],
                           :identification_number => row[1],
                           :work_number => row[2],
                           :name => (row[3].blank? ? Faker::Name.first_name + " (MN)" : row[3].capitalize),
                           :born_on => born_on,
                           born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
                           age: (born_on ? (Date.today - born_on) : 0),
                           :corabo => row[5],
                           :sex => (row[6] == "F" ? :female : :male),
                           # :arrival_cause => (arrival_causes[row[7]] || row[7]),
                           # :initial_arrival_cause => (initial_arrival_causes[row[7]] || row[7]),
                           :arrived_on => (row[8].blank? ? nil : Date.civil(*row[8].to_s.split(/\//).reverse.map(&:to_i))),
                           # :departure_cause => (departure_causes[row[9]] ||row[9]),
                           :departed_on => dead_on,
                           dead_at: (dead_on ? dead_on.to_datetime : nil)
                           )

        unless group = groups.detect do |g|
            (g.sex.blank? or g.sex == r.sex) and (g.minimal_age.blank? or r.age >= g.minimal_age) and (g.maximal_age.blank? or r.age < g.maximal_age)
          end
          raise "Cannot find a valid group for the given"
        end

        variant = ProductNatureVariant.import_from_nomenclature(group.member_nature)
        animal = Animal.create!(variant: variant,
                                name: r.name,
                                variety: variant.variety,
                                identification_number: r.identification_number,
                                work_number: r.work_number,
                                initial_born_at: r.born_at,
                                initial_dead_at: r.dead_at,
                                initial_owner: Entity.of_company,
                                initial_container: group.record.default_storage,
                                default_storage: group.record.default_storage
                                )
        # Sex is already known
        # animal.read!(:sex, r.sex, at: r.born_at)

        weighted_at = r.born_at
        variation = 0.05
        while (r.dead_at.nil? or weighted_at < r.dead_at) and weighted_at < Time.now
          age = (weighted_at - r.born_at).to_f
          weight = (age < 990 ? 700 * Math.sin(age / (100 * 2 * Math::PI)) + 50.0 : 750)
          weight += rand(weight * variation * 2) - (weight * variation)
          animal.read!(:net_mass, weight.in_kilogram.round(1), at: weighted_at)
          weighted_at += (70 + rand(40)).days + 30.minutes - rand(60).minutes
        end

        animal.read!(:healthy, true,  at: (now - 3.days))
        animal.read!(:healthy, false, at: (now - 2.days))
        animal.read!(:healthy, true,  at: now)

        group.record.add(animal, r.arrived_on)
        group.record.remove(animal, r.departed_on) if r.departed_on

        w.check_point
      end
    end
  end

  file = loader.path("synel", "inventaire.csv")
  if file.exist?
    loader.count :assign_parents_with_inventory do |w|

      CSV.foreach(file, encoding: "UTF-8", col_sep: "\t", headers: false) do |row|

        born_on = (row[4].blank? ? nil : Date.civil(*row[4].to_s.split(/\//).reverse.map(&:to_i)))
        incoming_on = (row[6].blank? ? nil : Date.civil(*row[6].to_s.split(/\//).reverse.map(&:to_i)))
        outgoing_on = (row[12].blank? ? nil : Date.civil(*row[12].to_s.split(/\//).reverse.map(&:to_i)))

        r = OpenStruct.new(:work_number => row[0],
                           :identification_number => (row[0] ? cattling_root_number+row[0].to_s : nil),
                           :name => (row[1].blank? ? Faker::Name.first_name+" (MN)" : row[1].capitalize),
                           :sex => (row[3].blank? ? nil : (row[3] == "F" ? :female : :male)),
                           :born_on => born_on,
                           born_at: (born_on ? born_on.to_datetime + 10.hours : nil),
                           :incoming_cause => row[5],
                           :incoming_on => incoming_on,
                           incoming_at: (incoming_on ? incoming_on.to_datetime + 10.hours : nil),
                           :mother_identification_number => row[7],
                           :mother_work_number => (row[7] ? row[7][-4..-1] : nil),
                           :mother_name => (row[8].blank? ? Faker::Name.first_name : row[8].capitalize),
                           :father_identification_number => row[9],
                           :father_work_number => (row[9] ? row[9][-4..-1] : nil),
                           :father_name => (row[10].blank? ? Faker::Name.first_name : row[10].capitalize),
                           :outgoing_cause => row[11],
                           :outgoing_on => outgoing_on,
                           outgoing_at: (outgoing_on ? outgoing_on.to_datetime + 10.hours : nil)
                           )
        # check if animal is present in DB
        next unless animal = Animal.find_by_identification_number(r.identification_number)

        linkeds = {}

        # Find or create mother
        unless linkeds[:mother] = Animal.find_by_identification_number(r.mother_identification_number)
          unless r.mother_identification_number.blank?
            linkeds[:mother] = Animal.create!(:variant_id => female_adult_cow.id,
                                              :name => r.mother_name,
                                              :variety => "bos",
                                              :identification_number => r.mother_identification_number,
                                              work_number: r.mother_work_number,
                                              :initial_owner => Entity.of_company,
                                              :initial_container => place,
                                              :default_storage => place)
          end
        end

        # Find or create father
        unless linkeds[:father] = Animal.find_by_identification_number(r.father_identification_number)
          unless r.father_identification_number.blank?
            linkeds[:father] = Animal.create!(:variant_id => male_adult_cow.id,
                                              :name => r.father_name,
                                              :variety => "bos",
                                              :identification_number => r.father_identification_number,
                                              work_number: r.father_work_number,
                                              :initial_owner => Entity.where(of_company: false).all.sample)
          end
        end

        for nature in [:mother, :father]
          next unless linkeds[nature]
          unless link = animal.links.find_by(nature: nature)
            link = animal.links.new(nature: nature, started_at: animal.born_at)
          end
          link.linked = linkeds[nature]
          link.save!
        end

        w.check_point
      end

  end
  end

  # attach picture if exist for each animal
  for animal in Animal.all
    picture_path = loader.path("alamano", "animals_pictures", "#{animal.work_number}.jpg")
    f = (picture_path.exist? ? File.open(picture_path) : nil)
    if f
      animal.picture = f
      animal.save!
      f.close
    end
  end

end
