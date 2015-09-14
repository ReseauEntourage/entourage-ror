Handlebars.registerHelper('pluralize', (val, single, plural) ->
  if (val > 1)
    val + ' ' + plural
  else
    val + ' ' + single
)