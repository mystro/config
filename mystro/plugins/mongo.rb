require 'mongo'

module Mystro
  module Plugin
    module Mongo
      include Mystro::Plugin::Base

      #on "environment:create" do |args|
      #  environment = args.shift
      #  if environment && environment.account && environment.account.name != "material"
      #    user = options[:user]
      #    pass = options[:pass]
      #    name = environment.name
      #    self.create_database(name, user, pass)
      #  end
      #end

      # this will blow away database on environment destroy
      # meaning if you just want to recreate the environment
      # you will lose data. disabled for now.
      #on "environment:destroy" do |args|
      #  environment = args.shift
      #  name        = environment.name
      #  self.destroy_database(name)
      #end

      command "mongo", "manage mongodb databases" do
        subcommand "list", "list all databases" do
          def execute
            list = Mystro::Plugin::Mongo.all.map {|e| {database: e[0], size: e[1]}}
            Mystro::Log.warn Mystro::CLI.list(%w{Database Size}, list)
          end
        end
        subcommand "create", "create a database" do
          parameter "NAME", "name of the database"
          parameter "[USER]", "user to add to database"
          parameter "[PASS]", "password of user to add to database"

          def execute
            Mystro::Plugin::Mongo.create_database(name, user, pass) unless test?
          end
        end
        subcommand "destroy", "destroy a database" do
          parameter "NAME", "name of the database"

          def execute
            Mystro::Plugin::Mongo.destroy_database(name) unless test?
          end
        end
        self.default_subcommand = "list"
      end

      class << self
        def options
          @options ||= config_for self
        end

        def connect
          @cxn ||= begin
            ::Mongo::Connection.new(options[:host], options[:port])
          end
        end

        def auth_admin
          db = @cxn.db("admin")
          db.authenticate(options[:admin_user], options[:admin_pass])
        end

        def all
          begin
            connect.database_info
          rescue ::Mongo::OperationFailure => e
            raise unless e.message =~ /need to login/
            raise unless auth_admin
            connect.database_info
          rescue => e
            Mystro::Log.error "exception: <#{e.class}> #{e.message} at #{e.backtrace.first}"
          end
        end

        def create_database(name, user, pass)
          db = connect.db("admin")
          raise "failed to authenticate" unless db.authenticate(options[:admin_user], options[:admin_pass])
          newdb = connect.db(name)
          newdb.add_user(user, pass) if user && pass
        end

        def destroy_database(name)
          db = connect.db("admin")
          raise "failed to authenticate" unless db.authenticate(options[:admin_user], options[:admin_pass])
          connect.drop_database(name)
        end
      end
    end
  end

end
