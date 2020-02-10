json.set! :data do
  json.array! @updated do |phytosanitary_usage|
    json.call(phytosanitary_usage, :id,
                                   :product_id,
                                   :ephy_usage_phrase,
                                   :crop,
                                   :species,
                                   :target_name,
                                   :description,
                                   :treatment,
                                   :dose_quantity,
                                   :dose_unit,
                                   :dose_unit_name,
                                   :dose_unit_factor,
                                   :pre_harvest_delay,
                                   :pre_harvest_delay_bbch,
                                   :applications_count,
                                   :applications_frequency,
                                   :development_stage_min,
                                   :development_stage_max,
                                   :usage_conditions,
                                   :untreated_buffer_aquatic,
                                   :untreated_buffer_arthropod,
                                   :untreated_buffer_plants,
                                   :decision_date,
                                   :state,
                                   :record_checksum)
  end

  json.array! @removed do |removed|
    json.call(removed, "id")
  end
end
