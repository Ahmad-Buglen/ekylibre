# -*- coding: utf-8 -*-
load_data :land_parcels do |loader|
  
  shapes = {}.with_indifferent_access
  
  path = loader.path("telepac", "ilot.shp")
  if path.exist?
    loader.count :telepac_shape_file_import do |w|
      #############################################################################
      # Import shapefile


      land_parcel_group_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel_cluster)

      RGeo::Shapefile::Reader.open(path.to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          born_at = Time.new(1, 1, 2)
          land_parcel_cluster = LandParcelCluster.create!(:variant_id => land_parcel_group_variant.id,
                                                          :name => LandParcel.model_name.human(locale: Preference[:language]) + " " + record.attributes['NUMERO'].to_s,
                                                          :work_number => record.attributes['NUMERO'].to_s,
                                                          :variety => "land_parcel_cluster",
                                                          :initial_born_at => born_at,
                                                          :initial_owner => Entity.of_company,
                                                          :identification_number => record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s)
          land_parcel_cluster.read!(:shape, record.geometry, at: born_at)
          ind_area = land_parcel_cluster.shape_area
          land_parcel_cluster.read!(:population, ind_area.in_hectare, at: born_at)
          if record.geometry
            shapes[record.attributes['NUMERO'].to_s] = Charta::Geometry.new(record.geometry).transform(:WGS84).to_rgeo
          end
          # puts "Record number #{record.index}:"
          # puts "  Geometry: #{record.geometry.as_text}"
          # puts "  Attributes: #{record.attributes.inspect}"
          w.check_point
        end
      end
    end

  end
  
  path = loader.path("telepac", "parcelle.shp")
  if path.exist?
    loader.count :telepac_landparcel_shape_file_import do |w|
      #############################################################################
      # Import landparcel_shapefile from TELEPAC
      # -- field_name
      # PACAGE
      # NUMERO_SI (land_parcel number)
      # NUMERO (land_parcel_cluster number id)
      # CAMPAGNE (campaign)
      # DPT_NUM (department zone number)
      # SURF_TOT (land_parcel_cluster area)
      # COMMUNE
      # TYPE (cf http://www.maine-et-loire.gouv.fr/IMG/pdf/Dossier-PAC-2013_notice_cultures-varietes.pdf)
      # CODE_VAR
      # SURF_DECL (land_parcel area)
      # TYPE_PARC
      # AGRI_BIO
      # ANNEE_ENGM

      land_parcel_variant = ProductNatureVariant.import_from_nomenclature(:land_parcel)
      

      RGeo::Shapefile::Reader.open(path.to_s, :srid => 2154) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          born_at = Time.new(1, 1, 2)

          # create a land parcel for each entries
          #
          land_parcel = LandParcel.create!(:variant_id => land_parcel_variant.id,
                                           :name => LandParcel.model_name.human(locale: Preference[:language]) + " " + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s,
                                           :work_number => "LP" + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s,
                                           :variety => "land_parcel",
                                           :initial_born_at => born_at,
                                           :initial_owner => Entity.of_company,
                                           :identification_number => "LP" + record.attributes['PACAGE'].to_s + record.attributes['CAMPAGNE'].to_s + record.attributes['NUMERO'].to_s + record.attributes['NUMERO_SI'].to_s)

          land_parcel.read!(:shape, record.geometry, at: born_at)
          ind_area = land_parcel.shape_area
          land_parcel.read!(:population, ind_area.in_hectare, at: born_at)
          if record.geometry
            shapes["LP" + record.attributes['NUMERO'].to_s + "-" + record.attributes['NUMERO_SI'].to_s] = Charta::Geometry.new(record.geometry).transform(:WGS84).to_rgeo
          end
          
          
          
          # create activities if option true
          if loader.manifest[:create_activities_from_telepac]
            # create a cultivable zone for each entries
            cultivable_zone_variant = ProductNatureVariant.find_by(:reference_name => :cultivable_zone) || ProductNatureVariant.import_from_nomenclature(:cultivable_zone)
            cultivable_zone = CultivableZone.create!(:variant_id => cultivable_zone_variant.id,
                                               :name => CultivableZone.model_name.human(locale: Preference[:language]) + " " + land_parcel.name,
                                               :work_number => land_parcel.work_number.tr("LP","ZC"),
                                               :variety => "cultivable_zone",
                                               :initial_born_at => land_parcel.born_at,
                                               :initial_owner => Entity.of_company,
                                               :identification_number => land_parcel.identification_number.tr("LP","ZC"))
      
              if zc_geometry = shapes[land_parcel.work_number]
                cultivable_zone.read!(:shape, zc_geometry, at: born_at)
                ind_area = cultivable_zone.shape_area
                
                cultivable_zone.read!(:population, land_parcel.population, at: born_at)
        
                # link cultivable zone and land parcel for each entries
                #
                cultivable_zone_membership = CultivableZoneMembership.where(group: cultivable_zone, member: land_parcel).first
                cultivable_zone_membership ||= CultivableZoneMembership.create!(:group => cultivable_zone,
                                                                                :member => land_parcel,
                                                                                :shape => Charta::Geometry.new(land_parcel.shape).transform(:WGS84).to_rgeo,
                                                                                :population => land_parcel.population
                                                                                )
              end
            
            # create a campaign if not exist
            # Get campaign
            unless campaign = Campaign.find_by(harvest_year: record.attributes['CAMPAGNE'].to_i)
              campaign = Campaign.create!(harvest_year: record.attributes['CAMPAGNE'].to_i, closed: false)
            end
            
            item = Nomen::ProductionNatures.where(telepac_crop_code: record.attributes['TYPE'].to_s).first
            # Create an activity if not exist with production_code
            unless activity_family = Nomen::ActivityFamilies[item.activity]
              raise "No activity family. (#{item.inspect})"          
            end
            
            unless activity = Activity.find_by(family: activity_family.name)  
              activity = Activity.create!(:nature => :main, :family => activity_family.name, :name => activity_family.human_name)
            end
            
            
            # create a production if not exist
            product_nature_variant = ProductNatureVariant.find_by(:reference_name => item.variant_support.to_s) || ProductNatureVariant.import_from_nomenclature(item.variant_support.to_s)
            
             if product_nature_variant
               
               unless production = Production.find_by(campaign_id: campaign.id, activity_id: activity.id, variant_id: product_nature_variant.id)
                production = activity.productions.create!(variant_id: product_nature_variant.id, campaign_id: campaign.id)
                end
               if product_support = cultivable_zone || nil
                # if exist, this production has static_support
                production.static_support = true
                production.save!
                # and create a support for this production
                support = production.supports.create!(storage_id: product_support.id, :started_at => Date.new((record.attributes['CAMPAGNE'].to_i)-1, 10, 01), :stopped_at => Date.new(record.attributes['CAMPAGNE'].to_i, 8, 01))
               end

             end

          end

          w.check_point
        end
      end
    end

  end


  
  path = loader.path("alamano", "zones", "cultivable_zones.shp")
  if path.exist?
    loader.count :cultivable_zones_shapes do |w|
      #############################################################################
      born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
      RGeo::Shapefile::Reader.open(path.to_s, :srid => 4326) do |file|
        # puts "File contains #{file.num_records} records."
        file.each do |record|
          if record.geometry
            shapes[record.attributes['number']] = Charta::Geometry.new(record.geometry)
          end
          w.check_point
        end
      end
    end
  end


  path = loader.path("alamano", "land_parcels.csv")
  if path.exist?
    born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
    loader.count :land_parcels do |w|
      CSV.foreach(path, headers: true) do |row|
        r = OpenStruct.new(name: row[0].to_s,
                           nature: (row[1].blank? ? nil : row[1].to_sym),
                           code: (row[2].blank? ? nil : row[2].to_s),
                           shape_number: (row[3].blank? ? nil : row[3].to_s),
                           ilot_code: (row[4].blank? ? nil : row[4].to_s),
                           place_code: (row[5].blank? ? nil : row[5].to_s),
                           soil_nature: (row[6].blank? ? nil : row[6].to_s),
                           available_water_capacity: (row[7].blank? ? nil : row[7].to_d),
                           soil_depth: (row[8].blank? ? nil : row[8].to_d)
                           )

        if zone = LandParcel.find_by_work_number(r.code)
          zone.update_attributes(:name => r.name)
          zone.save!
        else
          zone_variant = ProductNatureVariant.find_by(:reference_name => r.nature) || ProductNatureVariant.import_from_nomenclature(r.nature)
          pmodel = zone_variant.nature.matching_model
          zone = pmodel.create!(:variant_id => zone_variant.id, :work_number => r.code,
                                :name => r.name, :initial_born_at => born_at, :initial_owner => Entity.of_company, initial_shape: shapes[r.shape_number])
        end
        if container = Product.find_by_work_number(r.place_code)
          # container.add(zone, born_at)
          zone.update_attributes(initial_container: container)
          zone.save!
        end
        # link a land parcel to a land parcel cluster
        if land_parcel_cluster = LandParcelCluster.find_by_work_number(r.ilot_code)
          land_parcel_cluster.add(zone)
        end
        if r.soil_nature
          zone.read!(:soil_nature, r.soil_nature, at: born_at, force: true)
        end
        if r.soil_depth
          zone.read!(:soil_depth, r.soil_depth.in_centimeter, at: born_at, force: true)
        end
        if r.available_water_capacity_per_area
          zone.read!(:available_water_capacity_per_area, r.available_water_capacity_per_area.in_liter_per_square_meter, at: born_at, force: true)
        end
        w.check_point
      end
    end
  end



  path = loader.path("alamano", "cultivable_zones.csv")
  if path.exist?
    born_at = Time.new(1995, 1, 1, 10, 0, 0, "+00:00")
    loader.count :cultivable_zones do |w|
      CSV.foreach(path, headers: true) do |row|
        r = OpenStruct.new(name: row[0].to_s,
                           nature: (row[1].blank? ? nil : row[1].to_sym),
                           code: (row[2].blank? ? nil : row[2].to_s),
                           shape_number: (row[3].blank? ? nil : row[3].to_s),
                           members: row[4].blank? ? [] : row[4].to_s.strip.split(/[[:space:]]*\,[[:space:]]*/)
                           )

        unless zone = CultivableZone.find_by_work_number(r.code)
          zone_variant = ProductNatureVariant.find_by(:reference_name => r.nature) || ProductNatureVariant.import_from_nomenclature(r.nature)
          pmodel = zone_variant.nature.matching_model
          zone = pmodel.create!(:variant_id => zone_variant.id, :work_number => r.code,
                                :name => r.name, :initial_born_at => born_at, :initial_owner => Entity.of_company, initial_shape: shapes[r.shape_number])
        end
        if geometry = shapes[r.shape_number]
          zone.read!(:shape, geometry, at: born_at, force: true)
          zone.read!(:population, (zone.shape_area / zone.variant.net_surface_area.to_d(:square_meter)), at: born_at, force: true)
          # zone.read!(:net_surface_area, zone.shape_area, at: born_at)
        end

        # link cultivable zone and land parcel for each entries
        #
        for land_parcel_work_number in r.members
          if land_parcel = LandParcel.find_by_work_number(land_parcel_work_number)
            if land_parcel.shape
              cultivable_zone_membership = CultivableZoneMembership.where(group: zone, member: land_parcel).first
              cultivable_zone_membership ||= CultivableZoneMembership.create!( :group => zone,
                                                                               :member => land_parcel,
                                                                               :shape => land_parcel.shape,
                                                                               :population => (land_parcel.shape_area / land_parcel.variant.net_surface_area.to_d(:square_meter))
                                                                               )
            end
          end
        end
        # # Add available_water_capacity indicator
        # if r.land_parcel_available_water_capacity
        #   land_parcel.read!(:available_water_capacity_per_area, r.land_parcel_available_water_capacity.in_liter_per_square_meter, at: r.born_at)
        # end

        # # Add land_parcel in land_parcel_cluster group
        # land_parcel_cluster.add(land_parcel)

        w.check_point
      end
    end
  
  end



end
