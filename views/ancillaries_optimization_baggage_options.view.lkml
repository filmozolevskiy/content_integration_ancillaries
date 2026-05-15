view: ancillaries_optimization_baggage_options {
  sql_table_name: ota.ancillaries_optimization_baggage_options ;;

  # -------------------------
  # Keys (hidden)
  # -------------------------

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
    hidden: yes
  }

  dimension: ancillaries_optimization_baggage_id {
    type: number
    sql: ${TABLE}.ancillaries_optimization_baggage_id ;;
    hidden: yes
  }

  # -------------------------
  # 1. OPTION
  # -------------------------

  dimension: type {
    type: string
    sql: ${TABLE}.type ;;
    suggestions: ["carry_on", "first_checked", "second_checked"]
    group_label: "1. OPTION"
    label: "Bag Type"
    description: "carry_on / first_checked / second_checked. Small, closed value set."
  }

  dimension: fare_basis {
    type: string
    sql: ${TABLE}.fare_basis ;;
    group_label: "1. OPTION"
    label: "Fare Basis"
    description: "Fare basis code that priced this bag (e.g. VNN0AHM1, ACUD0QBJ). NULL when supplier did not return one."
  }

  dimension: fare_family {
    type: string
    sql: ${TABLE}.fare_family ;;
    group_label: "1. OPTION"
    label: "Fare Family"
    description: "Branded fare family (MAIN, BASIC, ...)."
  }

  # -------------------------
  # 2. ROUTE
  # -------------------------

  dimension: departure_code {
    type: string
    sql: ${TABLE}.departure_code ;;
    group_label: "2. ROUTE"
    label: "Departure"
    description: "IATA code of segment departure airport / city."
  }

  dimension: arrival_code {
    type: string
    sql: ${TABLE}.arrival_code ;;
    group_label: "2. ROUTE"
    label: "Arrival"
    description: "IATA code of segment arrival airport / city."
  }

  dimension: city_pair_index {
    type: number
    sql: ${TABLE}.city_pair_index ;;
    group_label: "2. ROUTE"
    label: "City Pair Index"
    description: "0-based index of the city pair within the booking."
  }

  dimension: segment_index {
    type: number
    sql: ${TABLE}.segment_index ;;
    group_label: "2. ROUTE"
    label: "Segment Index"
    description: "0-based index of the segment within the city pair."
  }

  dimension_group: departure {
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.departure_date ;;
    group_label: "2. ROUTE"
    label: "Departure"
    description: "Scheduled segment departure timestamp."
  }

  # -------------------------
  # 3. CARRIER
  # -------------------------

  dimension: marketing_carrier {
    type: string
    sql: ${TABLE}.marketing_carrier ;;
    group_label: "3. CARRIER"
    label: "Marketing Carrier"
    description: "Marketing airline code (3-letter)."
  }

  dimension: operating_carrier {
    type: string
    sql: ${TABLE}.operating_carrier ;;
    group_label: "3. CARRIER"
    label: "Operating Carrier"
    description: "Operating airline code. Often NULL on legacy paths; coalesce to marketing_carrier downstream."
  }

  dimension: codeshare_carrier_id {
    type: string
    sql: ${TABLE}.codeshare_carrier_id ;;
    group_label: "3. CARRIER"
    label: "Codeshare Carrier ID"
    description: "Codeshare carrier identifier when leg is operated by a different carrier."
  }

  # -------------------------
  # 4. PRICE
  # -------------------------

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
    group_label: "4. PRICE"
    label: "Currency"
    description: "Option currency. USD / CAD / EUR seen so far."
  }

  dimension: price {
    type: number
    sql: ${TABLE}.price ;;
    value_format: "#,##0.00"
    group_label: "4. PRICE"
    label: "Price"
    description: "Base price of the bag in Currency."
  }

  dimension: fees {
    type: number
    sql: ${TABLE}.fees ;;
    value_format: "#,##0.00"
    group_label: "4. PRICE"
    label: "Fees"
    description: "Fees component. Flat 10.00 across all current staging rows — likely a placeholder."
  }

  dimension: total {
    type: number
    sql: ${TABLE}.total ;;
    value_format: "#,##0.00"
    group_label: "4. PRICE"
    label: "Total"
    description: "price + fees, computed by the writer."
  }

  # -------------------------
  # 5. ALLOWANCE
  # -------------------------

  dimension: weight {
    type: number
    sql: ${TABLE}.weight ;;
    group_label: "5. ALLOWANCE"
    label: "Weight"
    description: "Weight allowance in weight_unit (commonly 23 / 32 kg)."
  }

  dimension: weight_unit_normalized {
    type: string
    sql: LOWER(${TABLE}.weight_unit) ;;
    group_label: "5. ALLOWANCE"
    label: "Weight Unit"
    description: "Lower-cased weight unit. Underlying column casing varies (KG vs kg)."
  }

  dimension: dimension_value {
    type: number
    sql: ${TABLE}.dimension ;;
    group_label: "5. ALLOWANCE"
    label: "Dimension"
    description: "Linear dimension (L+W+H) in dimension_unit. NULL on some legacy rows."
  }

  dimension: dimension_unit_normalized {
    type: string
    sql: LOWER(${TABLE}.dimension_unit) ;;
    group_label: "5. ALLOWANCE"
    label: "Dimension Unit"
    description: "Lower-cased dimension unit. Underlying column casing varies (CM vs cm); 'None' string seen on some Amadeus rows."
  }

  # -------------------------
  # Measures
  # -------------------------

  measure: count_options {
    type: count
    label: "Option Rows"
    description: "Number of priced option rows matching filters."
    group_label: "Counts"
  }

  measure: count_distinct_carriers {
    type: count_distinct
    sql: ${marketing_carrier} ;;
    label: "Distinct Marketing Carriers"
    description: "Distinct marketing carriers across the option rows."
    group_label: "Counts"
  }

  measure: avg_price {
    type: average
    sql: ${price} ;;
    value_format: "#,##0.00"
    label: "Avg Price"
    description: "Average bag price. Mix-aware — group by Bag Type and Currency for meaningful comparison."
    group_label: "Pricing"
  }

  measure: avg_total {
    type: average
    sql: ${total} ;;
    value_format: "#,##0.00"
    label: "Avg Total"
    description: "Average bag total (price + fees)."
    group_label: "Pricing"
  }

  measure: min_total {
    type: min
    sql: ${total} ;;
    value_format: "#,##0.00"
    label: "Min Total"
    description: "Cheapest bag total in the slice."
    group_label: "Pricing"
  }

  measure: max_total {
    type: max
    sql: ${total} ;;
    value_format: "#,##0.00"
    label: "Max Total"
    description: "Most expensive bag total in the slice."
    group_label: "Pricing"
  }
}
