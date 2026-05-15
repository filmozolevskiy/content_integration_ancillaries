view: ancillaries_optimization_baggage {
  sql_table_name: ota.ancillaries_optimization_baggage ;;

  # -------------------------
  # Keys (hidden)
  # -------------------------

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  # -------------------------
  # 1. DATE
  # -------------------------

  dimension_group: created {
    type: time
    timeframes: [raw, time, hour, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    group_label: "1. DATE"
    label: "Created"
    description: "When the BaggageOptimization call row was written (default CURRENT_TIMESTAMP). Primary time filter."
  }

  # -------------------------
  # 2. BOOKING CONTEXT
  # -------------------------

  dimension: search_id {
    type: string
    sql: ${TABLE}.search_id ;;
    group_label: "2. BOOKING CONTEXT"
    label: "Search ID (= bookings.debug_transaction_id)"
    description: "Booking session ID. Equals bookings.debug_transaction_id, NOT the search hash returned by qa-search. One booking may have multiple optimizer rows on the same search_id."
  }

  dimension: package_id {
    type: string
    sql: ${TABLE}.package_id ;;
    group_label: "2. BOOKING CONTEXT"
    label: "Package ID"
    description: "Package the user chose at checkout."
  }

  dimension: fare_type {
    type: string
    sql: ${TABLE}.fare_type ;;
    group_label: "2. BOOKING CONTEXT"
    label: "Fare Type"
    description: "Cabin / fare type — economy, business, etc."
  }

  dimension: validating_carrier {
    type: string
    sql: ${TABLE}.validating_carrier ;;
    group_label: "2. BOOKING CONTEXT"
    label: "Validating Carrier"
    description: "VC airline code (3-letter) of the booked package — e.g. AC, WS."
  }

  dimension: affiliate_id {
    type: number
    sql: ${TABLE}.affiliate_id ;;
    group_label: "2. BOOKING CONTEXT"
    label: "Affiliate ID"
    description: "Affiliate that drove the booking."
  }

  # -------------------------
  # 3. SUPPLIERS
  # -------------------------

  dimension: provider_gds {
    type: string
    sql: ${TABLE}.provider_gds ;;
    group_label: "3. SUPPLIERS"
    label: "Fares Supplier"
    description: "GDS that priced the underlying booking package (amadeus, dida, intelisys, flightroutes24, pkfare, ...). Matches bookings.gds lowercased. Distinct from the baggage supplier."
  }

  dimension: provider_office_id {
    type: string
    sql: ${TABLE}.provider_office_id ;;
    group_label: "3. SUPPLIERS"
    label: "Fares Office / PCC"
    description: "Office / PCC on the fares-supplier side."
  }

  dimension: gds {
    type: string
    sql: ${TABLE}.gds ;;
    group_label: "3. SUPPLIERS"
    label: "Baggage Supplier"
    description: "Ancillaries / baggage supplier called for THIS optimizer attempt (e.g. gordian, amadeus, dida). Gordian appears only here, never in Fares Supplier."
  }

  dimension: office_id {
    type: string
    sql: ${TABLE}.office_id ;;
    group_label: "3. SUPPLIERS"
    label: "Baggage Office / PCC"
    description: "Office / PCC used on the baggage-supplier side (e.g. YKXC42100 for CAD, LISPA2082 for EUR)."
  }

  # -------------------------
  # 4. CURRENCY
  # -------------------------

  dimension: user_currency {
    type: string
    sql: ${TABLE}.user_currency ;;
    group_label: "4. CURRENCY"
    label: "User Currency"
    description: "Currency the user saw at checkout."
  }

  dimension: site_currency {
    type: string
    sql: ${TABLE}.site_currency ;;
    group_label: "4. CURRENCY"
    label: "Site Currency"
    description: "POS site currency."
  }

  # -------------------------
  # 5. RESULT
  # -------------------------

  dimension: is_upgraded {
    type: yesno
    sql: ${TABLE}.is_upgraded = 1 ;;
    group_label: "5. RESULT"
    label: "Is Upgraded"
    description: "Row represents a fare-family upgrade scenario."
  }

  dimension: is_error {
    type: yesno
    sql: ${TABLE}.error IS NOT NULL ;;
    group_label: "5. RESULT"
    label: "Is Error"
    description: "Optimizer call failed (error column populated). Header row is still written on failure; child option rows are not."
  }

  dimension: error {
    type: string
    sql: ${TABLE}.error ;;
    group_label: "5. RESULT"
    label: "Error Message"
    description: "Full error text returned by the supplier. NULL on success."
  }

  dimension: error_signature {
    type: string
    sql: SUBSTRING(${TABLE}.error, 1, 120) ;;
    group_label: "5. RESULT"
    label: "Error Signature"
    description: "First 120 characters of error — safe for grouping. Common signatures: 'Serviceability failure: airline_not_supported', 'GDS Error: no ancillary', 'Incomplete search status [failed] returned', 'No fares found', 'Total price above original'."
  }

  dimension: execution_milliseconds {
    type: number
    sql: ${TABLE}.execution_milliseconds ;;
    group_label: "5. RESULT"
    label: "Execution (ms)"
    description: "Wall-clock duration of the supplier call. 0 on early errors. Fire-and-forget — does not block booking confirmation."
  }

  dimension: item_count {
    type: number
    sql: ${TABLE}.item_count ;;
    group_label: "5. RESULT"
    label: "Item Count"
    description: "Number of options written into ancillaries_optimization_baggage_options for this row. 0 on errors."
  }

  # -------------------------
  # 6. GUARDS (hidden helpers exposed as measures)
  # -------------------------

  dimension: is_ndcone {
    type: yesno
    hidden: yes
    sql: ${TABLE}.provider_gds = 'ndcone' OR ${TABLE}.gds = 'ndcone' ;;
    description: "NDC-ONE involvement. PR #52655 explicitly excludes NDC-ONE from the optimizer; this must stay at 0 in prod."
  }

  # -------------------------
  # Measures
  # -------------------------

  measure: count {
    type: count
    label: "Optimizer Calls"
    description: "Number of BaggageOptimization calls (parent rows) matching filters."
    group_label: "Counts"
  }

  measure: count_distinct_search {
    type: count_distinct
    sql: ${search_id} ;;
    label: "Distinct Bookings"
    description: "Distinct booking sessions (search_id) that triggered the optimizer. One booking can write multiple parent rows."
    group_label: "Counts"
  }

  measure: count_errors {
    type: count
    filters: [is_error: "yes"]
    label: "Errors"
    description: "Optimizer calls with error IS NOT NULL."
    group_label: "Counts"
  }

  measure: count_ndcone_guard {
    type: count
    filters: [is_ndcone: "yes"]
    label: "NDC-ONE Guard"
    description: "Must stay 0 in prod once PR #52655 is live — NDC-ONE is excluded from the new strategy. Non-zero = bug → revert."
    group_label: "Counts"
  }

  measure: error_rate {
    type: number
    sql: 1.0 * ${count_errors} / NULLIF(${count}, 0) ;;
    value_format: "0.00%"
    label: "Error Rate"
    description: "Errors / Optimizer Calls."
    group_label: "Rates"
  }

  measure: total_items {
    type: sum
    sql: ${item_count} ;;
    sql_distinct_key: ${id} ;;
    label: "Total Options Written"
    description: "Sum of item_count across parent rows. sql_distinct_key prevents fan-out when joined to the options view."
    group_label: "Volume"
  }

  measure: offers_per_request {
    type: average
    sql: ${item_count} ;;
    sql_distinct_key: ${id} ;;
    value_format: "#,##0.00"
    label: "Offers per Request"
    description: "Avg item_count per optimizer call (request). Calls with zero item_count count as 0 — so this drops below the bag-types-offered ceiling whenever an attempt returned no offer. sql_distinct_key prevents inflation when joined to the options view."
    group_label: "Coverage"
  }

  measure: avg_execution_ms {
    type: average
    sql: ${execution_milliseconds} ;;
    sql_distinct_key: ${id} ;;
    value_format: "#,##0"
    label: "Avg Execution (ms)"
    description: "Average supplier call duration. sql_distinct_key prevents fan-out when joined to the options view."
    group_label: "Latency"
  }

  measure: max_execution_ms {
    type: max
    sql: ${execution_milliseconds} ;;
    value_format: "#,##0"
    label: "Max Execution (ms)"
    description: "Max supplier call duration in the window. Long tails (Amadeus / Dida > 30s) are expected — optimizer is fire-and-forget."
    group_label: "Latency"
  }
}
