module Proxy::OpenSCAP
  class PluginConfiguration
    def load_dependency_injection_wirings(container, settings)
      container.singleton_dependency :openscap_initializer, ( lambda do
        ::Proxy::OpenSCAP::OpenscapInitializer.new
      end)
    end

    def load_classes
      require 'smart_proxy_openscap/openscap_initializer'
    end
  end
end
