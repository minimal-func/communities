# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/providers", under: "providers"

# Active Admin JavaScript
pin "jquery" # @3.7.1
pin "jquery-ui", to: "https://ga.jspm.io/npm:jquery-ui@1.14.1/ui/widget.js"
pin "jquery-ujs", to: "https://ga.jspm.io/npm:jquery-ujs@1.2.3/src/rails.js"

active_admin_path = Gem.loaded_specs["activeadmin"].full_gem_path
pin_all_from File.join(active_admin_path, "app/javascript/active_admin"), under: "active_admin", to: "active_admin/"
