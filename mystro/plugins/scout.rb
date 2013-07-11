require 'rubygems'
require 'scout_api'

module Mystro
  module Plugin
    module Scout
      include Mystro::Plugin::Base

      #on "environment:create" do |_|
      #end

      #on "environment:destroy" do |_|
      #end

      #on "instance:create" do |args|
      #end

      on "compute:destroy" do |args|
        instance = args.shift
        compute  = args.shift
        name     = compute.short
        Mystro::Log.info "scout compute:destroy '#{compute.short}' '#{compute.long}'"
        #unless name.nil? || name.empty?
        #  self.instance_destroy(name)
        #end
      end

      command "scout", "test scout configuration" do
        def execute
          list = Mystro::Plugin::Scout.test
          rows = []
          list.each do |c|
            rows << [c[:hostname], c[:checkup_status], c[:last_checkin]]
          end
          print_table(%w{Hostname Status LastCheckIn}, rows)
        end
      end

      class << self
        def configure
          @config ||= config_for self
          @scout  ||= ::Scout::Account.new(@config[:account], @config[:email], @config[:secret])
        end

        def test
          configure
          ::Scout::Server.all
        end

        def instance_destroy(name)
          configure
          server = ::Scout::Server.first(:name => name)
          ::Scout::Server.delete(server.id) if server
        rescue => e
          Mystro::Log.error "#{self.class} : #{e.message} at #{e.backtrace.first}"
        end

        def environment_destroy(name)
          configure
          all  = ::Scout::Server.all
          list = all.select { |e| e.name =~ /\.#{name}\./ }
        end
      end
    end
  end

  #module Command
  #  class Scout < Clamp::Command
  #    def execute
  #      list = Mystro::Plugin::Scout.test
  #      rows = []
  #      list.each do |c|
  #        rows << [c[:hostname], c[:checkup_status], c[:last_checkin]]
  #      end
  #      table(%w{Hostname Status LastCheckIn}, rows)
  #    end
  #  end
  #end
end