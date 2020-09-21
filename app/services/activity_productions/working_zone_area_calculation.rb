# frozen_string_literal: true

module ActivityProductions
  class WorkingZoneAreaCalculation

    SELECT_SRID = <<~SQL
      SELECT CASE
        WHEN string_value = 'WGS84' THEN 4326
        WHEN string_value = 'RGF93' THEN 2154
        WHEN string_value ~ '_' THEN SPLIT_PART(string_value, '_', 2)::INTEGER
        ELSE 0
      END AS srid
      FROM preferences WHERE name = 'map_measure_srs' LIMIT 1
    SQL

    PLANTING = Procedo::Procedure.of_category(:planting).map do |procedure|
      procedure.name.to_s.insert(0, "'").insert(-1, "'")
    end.join(', ')

    def compute_working_zone_area(activity_production)
      activity_production_working_zone_area = ActiveRecord::Base.connection.execute <<~SQL
        SELECT
          activity_production_id,
          SUM(area) AS working_zone_area
        FROM (
          SELECT DISTINCT
            interventions.id AS intervention_id,
            intervention_parameters.id,
            products.id,
            activity_productions.id AS activity_production_id,
            CASE
              WHEN interventions.procedure_name NOT IN (#{PLANTING})
              THEN ST_Area(ST_Transform(intervention_parameters.working_zone,
                (#{SELECT_SRID}))
                )/10000
              /* if procedure is planting, it should take the initial shape of
                 the associated products                                    */
              ELSE ST_Area(ST_Transform(products.initial_shape,
                (#{SELECT_SRID})))/10000
            END AS area
          FROM interventions
          INNER JOIN intervention_parameters
            ON interventions.id = intervention_parameters.intervention_id
            AND (CASE
              WHEN interventions.procedure_name IN (#{PLANTING}) THEN
                'InterventionOutput'
              ELSE 'InterventionTarget'
            END) = intervention_parameters.type
          INNER JOIN products
            ON products.id = intervention_parameters.product_id
          INNER JOIN activity_productions
            ON activity_productions.id = products.activity_production_id
          -- only with interventions with nature record and state is not rejected
          WHERE interventions.state != 'rejected'
          AND interventions.nature = 'record'
        ) subquery
        WHERE activity_production_id = #{activity_production.id}
        GROUP BY activity_production_id;
      SQL

      return 0.0.in(:hectare) if activity_production_working_zone_area.values.empty?

      activity_production_working_zone_area.first['working_zone_area'].to_d.in(:hectare)
    end
  end
end
