require 'zip'

module Ekylibre
  module FirstRun

    COUNTER_MAX = -1
    

    LOADERS = [:base, :general_ledger, :entities, :buildings, :products, :animals, :land_parcels, :productions, :analyses, :sales, :deliveries, :interventions, :guides]
    
    class CountExceeded < StandardError
    end
    
    autoload :Counter,  'ekylibre/first_run/counter'
    autoload :Booker,   'ekylibre/first_run/booker'
    autoload :Loader,   'ekylibre/first_run/loader'
    autoload :Manifest, 'ekylibre/first_run/manifest'

    IMPORTS = {
      telepac: {
        shapes: :file,
        shapes_index: :file,
        database: :file,
        projection: :file
      },
      istea: {
        general_ledger: :file
      }
    }

    class MissingData < StandardError
    end

    MIME = "application/vnd.ekylibre.first-run.archive"

    # Register FRA format unless is already set
    Mime::Type.register(MIME, :fra) unless defined? Mime::FRA

    class << self

      def path
        Rails.root.join("db", "first_runs")
      end

      def build(path)
        spec = YAML.load_file(path).deep_symbolize_keys

        puts spec.inspect

        # files = {}
        manifest = Manifest.new

        # General
        manifest[:locale] = spec[:locale] || I18n.default_locale
        manifest[:country] = spec[:country] || "fr"
        manifest[:currency] = spec[:currency] || "EUR"

        # Entity
        if spec[:entity]
          spect[:entity] = {name: spec[:entity].to_s} unless spec[:entity].is_a?(Hash)
          manifest[:entity] = spec[:entity]
          unless spec[:entity][:picture]
            manifest.store(:entity, :picture, Rails.root.join("app", "assets", "images", "icon", "store.png"))
          end
        else
          raise MissingData, "Need entity data."
        end

        # Users
        unless spec[:users]
          spec[:users] = {'admin@ekylibre.org' => {
              first_name: 'Admin',
              last_name: 'EKYLIBRE',
              password: '12345678'
            }
          }
        end
        manifest[:users] = {}
        for email, details in spec[:users]
          details[:password] ||= User.give_password(8, :normal)
          manifest[:users][email] = details
        end

        # Imports
        manifest[:imports] = {}
        for import, parameters in IMPORTS
          if spec[:imports][import]
            manifest[:imports][import] = {}
            for param, type in parameters
              if type == :file
                manifest.add_file(:imports, import, param, path.dirname.join(spec[:imports][import][param]))
                manifest[:imports, import, param] = path.dirname.join(spec[:imports][import][param])

                doc = path.dirname.join(spec[:imports][import][param])
                name = "#{param}#{doc.extname}"
                files["imports/#{import}/#{name}"] = doc
                manifest[:imports][import][param] = name
              else
                manifest[:imports][import][param] = spec[:imports][import][param]
              end
            end
          end
        end
        manifest.delete(:imports) if manifest[:imports].empty?

        manifest.build(path.realpath.parent.join(path.basename(path.extname).to_s + ".fra"))
      end

      def check(file)
      end

      def seed(file)

      end

    end

  end
end
