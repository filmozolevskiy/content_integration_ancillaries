connection: "ota"

include: "/views/**/*.view.lkml"

explore: ancillaries_optimization_baggage {
  label: "Ancillaries Optimization"
  description: "One row per BaggageOptimization call on a confirmed booking, joined to its returned options."

  join: ancillaries_optimization_baggage_options {
    type: left_outer
    relationship: one_to_many
    sql_on: ${ancillaries_optimization_baggage.id}
         = ${ancillaries_optimization_baggage_options.ancillaries_optimization_baggage_id} ;;
  }

  always_filter: {
    filters: [ancillaries_optimization_baggage.created_date: "30 days"]
  }
}
