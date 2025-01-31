--# MAIN ACTIVITY
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   (SELECT SUM(ap.size_value) FROM activity_productions AS ap
   WHERE ap.activity_id = a.id AND ap.id IN (
     SELECT apc.activity_production_id
      FROM activity_productions_campaigns AS apc WHERE apc.campaign_id = c.id)
   ) AS activity_size_value,
   a.size_unit_name AS activity_size_unit,
   'main_direct_product' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   aco.variant_id AS output_variant_id,
   aco.variant_unit_id AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
JOIN activity_cost_outputs AS aco ON (aco.activity_id = a.id)
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'revenue' AND abi.variant_id = aco.variant_id
AND a.nature = 'main'
GROUP BY a.id, c.id, aco.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   (SELECT SUM(ap.size_value) FROM activity_productions AS ap
   WHERE ap.activity_id = a.id AND ap.id IN (
     SELECT apc.activity_production_id
      FROM activity_productions_campaigns AS apc WHERE apc.campaign_id = c.id)
   ) AS activity_size_value,
   a.size_unit_name AS activity_size_unit,
   'other_direct_product' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
JOIN activity_cost_outputs AS aco ON (aco.activity_id = a.id)
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'revenue' AND abi.variant_id <> aco.variant_id
AND a.nature = 'main'
GROUP BY a.id, c.id, aco.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   (SELECT SUM(ap.size_value) FROM activity_productions AS ap
   WHERE ap.activity_id = a.id AND ap.id IN (
     SELECT apc.activity_production_id
      FROM activity_productions_campaigns AS apc WHERE apc.campaign_id = c.id)
   ) AS activity_size_value,
   a.size_unit_name AS activity_size_unit,
   'fixed_direct_charge' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'expense' AND abi.nature <> 'dynamic'
AND a.nature = 'main'
GROUP BY a.id, c.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   (SELECT SUM(ap.size_value) FROM activity_productions AS ap
   WHERE ap.activity_id = a.id AND ap.id IN (
     SELECT apc.activity_production_id
      FROM activity_productions_campaigns AS apc WHERE apc.campaign_id = c.id)
   ) AS activity_size_value,
   a.size_unit_name AS activity_size_unit,
   'proportional_direct_charge' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'expense' AND abi.nature = 'dynamic'
AND a.nature = 'main'
GROUP BY a.id, c.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   '1' AS activity_size_value,
   'unit' AS activity_size_unit,
   'global_indirect_product' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'revenue'
AND a.nature = 'auxiliary'
GROUP BY a.id, c.id
UNION ALL
SELECT
   a.id AS activity_id,
   c.id AS campaign_id,
   '1' AS activity_size_value,
   'unit' AS activity_size_unit,
   'global_indirect_charge' AS economic_indicator,
   SUM(abi.global_amount) AS amount,
   NULL AS output_variant_id,
   NULL AS output_variant_unit_id

FROM activity_budgets AS ab
JOIN activities AS a ON ab.activity_id = a.id
JOIN campaigns AS c ON ab.campaign_id = c.id
LEFT JOIN activity_budget_items AS abi ON abi.activity_budget_id = ab.id
WHERE abi.direction = 'expense'
AND a.nature = 'auxiliary'
GROUP BY a.id, c.id
ORDER BY activity_id, campaign_id
