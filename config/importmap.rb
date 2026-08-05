# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/providers", under: "providers"
pin_all_from "app/javascript/lib", under: "lib"

# Active Admin JavaScript
pin "jquery" # @3.7.1
pin "jquery-ui", to: "https://ga.jspm.io/npm:jquery-ui@1.14.1/ui/widget.js"
pin "jquery-ujs", to: "https://ga.jspm.io/npm:jquery-ujs@1.2.3/src/rails.js"

active_admin_path = Gem.loaded_specs["activeadmin"].full_gem_path
pin_all_from File.join(active_admin_path, "app/javascript/active_admin"), under: "active_admin", to: "active_admin"
pin "@editorjs/editorjs", to: "@editorjs--editorjs.js" # @2.31.6
pin "@editorjs/checklist", to: "@editorjs--checklist.js" # @1.6.0
pin "@editorjs/code", to: "@editorjs--code.js" # @2.9.4
pin "@editorjs/delimiter", to: "@editorjs--delimiter.js" # @1.4.2
pin "@editorjs/embed", to: "@editorjs--embed.js" # @2.8.0
pin "@editorjs/header", to: "@editorjs--header.js" # @2.8.9
pin "@editorjs/image", to: "@editorjs--image.js" # @2.10.3
pin "@editorjs/inline-code", to: "@editorjs--inline-code.js" # @1.5.2
pin "@editorjs/list", to: "@editorjs--list.js" # @2.0.9
pin "@editorjs/marker", to: "@editorjs--marker.js" # @1.4.0
pin "@editorjs/quote", to: "@editorjs--quote.js" # @2.7.6
pin "@editorjs/raw", to: "@editorjs--raw.js" # @2.5.1
pin "@editorjs/table", to: "@editorjs--table.js" # @2.4.5
pin "@editorjs/warning", to: "@editorjs--warning.js" # @1.4.1
