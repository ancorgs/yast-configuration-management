require "yast"
require "cheetah"
require "configuration_management/cfa/minion"
require "configuration_management/cfa/minion_yast_configuration_management"
require "configuration_management/configurators/base"
require "pathname"

module Yast
  module ConfigurationManagement
    module Configurators
      # Salt configurator
      #
      # This class is responsible for configuring Salt before running it.
      class Salt < Base
        PRIVATE_KEY_PATH = "/etc/salt/pki/minion/minion.pem".freeze
        PUBLIC_KEY_PATH = "/etc/salt/pki/minion/minion.pub".freeze

        mode(:masterless) do
          fetch_config(config.states_url, config.work_dir) if config.states_url
          fetch_config(config.pillar_url, config.pillar_root) if config.pillar_url
          overwrite_configuration
          Yast::WFM.CallFunction("configuration_management_formula",
            [config.states_root.to_s, config.formulas_root.to_s, config.pillar_root.to_s])
        end

        mode(:client) do
          fetch_keys(config.keys_url, private_key_path, public_key_path)
          update_configuration
        end

        # List of packages to install
        #
        # * `salt` includes the `salt-call` command.
        # * `salt-minion` is only needed in client mode
        #
        # @return [Hash] Packages to install/remove
        def packages
          salt_packages = ["salt"]
          salt_packages << "salt-minion" if config.mode == :client
          { "install" => salt_packages }
        end

        # Return a list of services which have to be enabled
        #
        # @return [[Array<String>] List of services
        def services
          ["salt-minion"]
        end

      private

        # Update the minion's configuration file
        #
        # At this time, only the master server is handled.
        #
        # @see Yast::ConfigurationManagement::Configurators::Base#update_configuration
        # @see #master
        def update_configuration
          return unless config.master.is_a?(::String)
          log.info "Updating minion configuration file"
          config_file = CFA::Minion.new
          config_file.load
          config_file.master = config.master
          config_file.save
        end

        # Update the minion's configuration file in
        # /etc/salt/minion.d/file_roots.conf
        def overwrite_configuration
          config_file = CFA::MinionYastConfigurationManagement.new
          config_file.load
          config_file.set_file_roots([config.states_root, config.formulas_root])
          config_file.save
        end

        # Return path to private key
        #
        # @return [Pathname] Path to private key
        def private_key_path
          Pathname(::File.join(Yast::Installation.destdir, PRIVATE_KEY_PATH))
        end

        # Return path to public key
        #
        # @return [Pathname] Path to public_key
        def public_key_path
          Pathname(::File.join(Yast::Installation.destdir, PUBLIC_KEY_PATH))
        end
      end
    end
  end
end
