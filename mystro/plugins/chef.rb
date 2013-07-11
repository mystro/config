require 'rubygems'

require 'chef'
require 'chef/config'
require 'chef/api_client'
require 'chef/node'
require 'chef/environment'

module Mystro
  module Plugin
    module Chef
      include Mystro::Plugin::Base

      on "environment:create" do |args|
        environment = args.shift
        name        = environment.name
        self.environment_create(name)
      end

      on "environment:destroy" do |args|
        environment = args.shift
        name        = environment.name
        self.environment_destroy(name)
      end

      #on "compute:create" do |args|
      #  # do nothing
      #  # the instance will add itself through the chef-client call in userdata package
      #end

      on "compute:destroy" do |args|
        instance = args.shift
        compute  = args.shift
        short = compute.short
        long = compute.long
        Mystro::Log.info "chef compute:destroy #{short}"
        self.client_delete(compute.short)
        self.node_delete(compute.short)
        # delete nodes and clients, HARDER!
        Mystro::Log.info "chef compute:destroy #{long}"
        self.client_delete(compute.long)
        self.node_delete(compute.long)
      end

      command "chef", "test chef configuration" do
        self.default_subcommand = "client"
        subcommand "client", "manage chef clients" do
          self.default_subcommand = "list"
          subcommand "list", "list chef clients" do
            def execute
              list = Mystro::Plugin::Chef.client_list
              rows = []
              list.each do |c|
                rows << {name: c[0], location: c[1]}
              end
              Mystro::Log.warn Mystro::CLI.list(%w{Name Location}, rows)
            end
          end
          subcommand "destroy", "destroy chef client" do
            parameter "name", "name of client"
            def execute
              self.client_delete(name)
            end
          end
        end
        subcommand "node", "manage chef nodes" do
          self.default_subcommand = "list"
          subcommand "list", "list chef nodes" do
            def execute
              list = Mystro::Plugin::Chef.node_list
              rows = []
              list.each do |c|
                rows << {name: c[0], location: c[1]}
              end
              Mystro::Log.warn Mystro::CLI.list(%w{Name Location}, rows)
            end
          end
          subcommand "destroy", "destroy chef client" do
            parameter "name", "name of node"
            def execute
              self.client_delete(name)
            end
          end
        end
        subcommand "environment", "manage chef environments" do
          self.default_subcommand = "list"
          subcommand "list", "list chef environments" do
            def execute
              list = Mystro::Plugin::Chef.environment_list
              rows = []
              list.each do |c|
                rows << {name: c[0], location: c[1]}
              end
              Mystro::Log.warn Mystro::CLI.list(%w{Name Location}, rows)
            end
          end
          subcommand "destroy", "destroy chef client" do
            parameter "name", "name of environment"
            def execute
              self.environment_destroy(name)
            end
          end
          subcommand "kill", "destroy chef environment and any nodes or clients that contain the name" do
            parameter "name", "name of environment"
            def execute
              clients = Mystro::Plugin::Chef.client_list.map {|e| {name: e[0], location: e[1]}}.select {|e| e[:name] =~ /\.#{name}\./}
              nodes = Mystro::Plugin::Chef.node_list.map {|e| {name: e[0], location: e[1]}}.select {|e| e[:name] =~ /\.#{name}\./}
              Mystro::Log.warn "environment: #{name}"
              Mystro::Log.warn "clients"
              Mystro::Log.warn Mystro::CLI.list(%w{Name Location}, clients)
              Mystro::Log.warn "nodes"
              Mystro::Log.warn Mystro::CLI.list(%w{Name Location}, nodes)
              Mystro::Log.warn "Are you sure? This cannot be undone! enter the name of the environment:"
              e = $stdin.gets.chomp
              if e === name
                clients.each do |c|
                  Mystro::Log.warn "client delete: #{c[:name]}"
                  Mystro::Plugin::Chef.client_delete(c[:name])
                end
                nodes.each do |n|
                  Mystro::Log.warn "node delete: #{n[:name]}"
                  Mystro::Plugin::Chef.node_delete(n[:name])
                end
                Mystro::Plugin::Chef.environment_destroy(name)
              end
            end
          end
        end
      end

      class << self
        def configure
          @config ||= config_for self
          @chef   ||= ::Chef::Config.from_file(File.expand_path(@config[:knife]))
        end

        def test
          self.client_list
        end

        def role_list
          configure
          # TODO: better error handling
          list = ::Chef::Role.list
          list.map do |k, v|
            r = ::Chef::Role.load(k)
            r.to_hash
          end
        end

        def environment_create(name)
          configure
          env = ::Chef::Environment.new
          env.name(name)
          env.description("created by Mystro")
          env.save
          true
        rescue => e
          Mystro::Log.error "*** chef exception: #{e.message}"
          false
        end

        def environment_destroy(name)
          configure
          env = ::Chef::Environment.load(name) rescue nil
          env.destroy if env
          true
        rescue => e
          Mystro::Log.error "*** chef exception: #{e.message}"
          false
        end

        def environment_list
          configure
          ::Chef::Environment.list
        end

        def client_delete(name)
          configure
          # TODO: better error handling
          puts "NAME:#{name}"
          client = ::Chef::ApiClient.load(name)
          client.destroy if client
        rescue => e
          Mystro::Log.error "*** chef exception: #{e.message} at #{e.backtrace.first}"
          false
        end

        def client_list
          configure
          # TODO: better error handling
          ::Chef::ApiClient.list
        end

        def node_list
          configure
          # TODO: better error handling
          ::Chef::Node.list
        end

        def node_delete(name)
          configure
          # TODO: better error handling
          node = ::Chef::Node.load(name)
          node.destroy if node
        rescue => e
          Mystro::Log.error "*** chef exception: #{e.message} at #{e.backtrace.first}"
          false
        end
      end
    end
  end

end
