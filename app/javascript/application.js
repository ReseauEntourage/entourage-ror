// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

import "jquery"
import "jquery-ui"
import "select2"
import "moment"
import "daterangepicker"
import "bootstrap-multiselect"
import "chartkick"
// import "Chart.bundle"
import { Chart } from "chart.js"

const customContext = require.context("./custom", true, /\.js$/)
customContext.keys().forEach(customContext)
