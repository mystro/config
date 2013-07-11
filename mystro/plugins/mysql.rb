module Mystro
  module Plugin
    class Mysql < Base
      # work in progress
    end
  end

  module Command
    module Mysql
      class List < Abstract
        def execute
          db = Mystro::Connection.database

          list = db.all.sort
          print_table(%w{Database Size}, list)
        end
      end

      class Create < Abstract
        parameter "NAME", "name of the database"
        parameter "[USER]", "user to add to database"
        parameter "[PASS]", "password of user to add to database"

        def execute
          db = Mystro::Connection.database
          db.create_database(name, user, pass) unless test?
        end
      end

      class Destroy < Abstract
        parameter "NAME", "name of the database"

        def execute
          db = Mystro::Connection.database
          db.destroy_database(name) unless test?
        end
      end

      class Main < Abstract
        subcommand "list", "list all databases", List
        subcommand "create", "create a database", Create
        subcommand "destroy", "destroy a database", Destroy
        self.default_subcommand = "list"
      end
    end
  end
end